# Paystack setup

1. Open `backend/.env.local` and add:

   ```env
   PAYSTACK_SECRET_KEY=sk_test_your_key
   APP_PUBLIC_URL=https://your-public-backend.example
   ```

   Find the test key in **Paystack Dashboard → Settings → API Keys & Webhooks**. Never put the secret key in Flutter's `.env` or commit it.

2. Deploy the `20260717150000_add_patient_identity_cards.sql` Supabase migration.

3. Deploy the backend on a public HTTPS address. In the Paystack dashboard, set the webhook URL to:

   ```text
   https://your-public-backend.example/api/v1/payments/paystack/webhook
   ```

4. Restart/redeploy the backend after changing environment variables. Start payments through `POST /api/v1/payments/paystack/initialize`; the backend supplies the signed checkout URL and records the transaction.

5. Test with Paystack test mode first. A payment is treated as complete only after the signed `charge.success` webhook updates the transaction—not merely after the customer returns from checkout.
