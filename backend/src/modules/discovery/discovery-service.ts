import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import type { PharmacyDiscoveryQuery } from "@/modules/discovery/discovery-schema";

interface MedicineRelation {
  canonical_name: string;
  generic_name: string | null;
  brand_name: string | null;
  strength: string | null;
}

interface InventoryRelation {
  quantity: number;
  reorder_level: number;
  medicines: MedicineRelation | MedicineRelation[] | null;
}

function medicineFor(item: InventoryRelation) {
  return Array.isArray(item.medicines) ? item.medicines[0] : item.medicines;
}

export async function discoverPharmacies(input: PharmacyDiscoveryQuery) {
  const { data, error } = await getSupabaseAdmin()
    .from("pharmacies")
    .select(
      "id, name, location, latitude, longitude, operating_hours, verification_status, inventory_items(quantity, reorder_level, medicines(canonical_name, generic_name, brand_name, strength))",
    )
    .eq("is_active", true)
    .is("inventory_items.deleted_at", null)
    .order("name", { ascending: true })
    .limit(100);

  if (error) {
    throw new HttpError(
      502,
      "DISCOVERY_UNAVAILABLE",
      "Nearby pharmacies could not be loaded.",
    );
  }

  const search = input.search.toLowerCase();
  return (data ?? [])
    .map((pharmacy) => {
      const inventory = (pharmacy.inventory_items ?? []) as InventoryRelation[];
      const medicines = inventory
        .map((item) => {
          const medicine = medicineFor(item);
          if (!medicine) return null;
          return {
            name: medicine.canonical_name,
            genericName: medicine.generic_name,
            brandName: medicine.brand_name,
            strength: medicine.strength,
            quantity: item.quantity,
            reorderLevel: item.reorder_level,
            stockLevel:
              item.quantity <= 0
                ? "outOfStock"
                : item.quantity <= item.reorder_level
                  ? "lowStock"
                  : "inStock",
          };
        })
        .filter((item): item is NonNullable<typeof item> => item !== null);

      const matchesPharmacy =
        !search ||
        pharmacy.name.toLowerCase().includes(search) ||
        pharmacy.location.toLowerCase().includes(search);
      const matchingMedicines = search
        ? medicines.filter((medicine) =>
            [
              medicine.name,
              medicine.genericName,
              medicine.brandName,
              medicine.strength,
            ].some((value) => value?.toLowerCase().includes(search)),
          )
        : medicines;

      if (!matchesPharmacy && matchingMedicines.length === 0) return null;

      return {
        id: pharmacy.id,
        name: pharmacy.name,
        location: pharmacy.location,
        latitude: pharmacy.latitude,
        longitude: pharmacy.longitude,
        operatingHours: pharmacy.operating_hours,
        verificationStatus: pharmacy.verification_status,
        medicines: matchesPharmacy ? medicines : matchingMedicines,
      };
    })
    .filter((item): item is NonNullable<typeof item> => item !== null)
    .slice(0, input.limit);
}
