import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { SubscriptionInput, ShippingMethod } from '@/hooks/use-subscriptions';

interface Props {
  onSubmit: (input: SubscriptionInput) => Promise<void> | void;
  isSubmitting?: boolean;
}

const empty: SubscriptionInput = {
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  street: '',
  postal_code: '',
  city: '',
  country: 'Deutschland',
  address_extra: '',
  shipping_method: 'standard',
};

export default function SubscriptionForm({ onSubmit, isSubmitting }: Props) {
  const [form, setForm] = useState<SubscriptionInput>(empty);

  const update = <K extends keyof SubscriptionInput>(k: K, v: SubscriptionInput[K]) =>
    setForm((f) => ({ ...f, [k]: v }));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSubmit({
      ...form,
      phone: form.phone?.trim() || null,
      address_extra: form.address_extra?.trim() || null,
    });
    setForm(empty);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <h3 className="font-semibold mb-3">1. Kontaktdaten</h3>
        <div className="grid gap-3 md:grid-cols-2">
          <div className="space-y-1">
            <Label htmlFor="first_name">Vorname *</Label>
            <Input id="first_name" required value={form.first_name}
              onChange={(e) => update('first_name', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="last_name">Nachname *</Label>
            <Input id="last_name" required value={form.last_name}
              onChange={(e) => update('last_name', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="email">E-Mail *</Label>
            <Input id="email" type="email" required value={form.email}
              onChange={(e) => update('email', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="phone">Telefon (optional)</Label>
            <Input id="phone" value={form.phone ?? ''}
              onChange={(e) => update('phone', e.target.value)} />
          </div>
        </div>
      </div>

      <div>
        <h3 className="font-semibold mb-3">2. Lieferadresse</h3>
        <div className="grid gap-3 md:grid-cols-2">
          <div className="space-y-1 md:col-span-2">
            <Label htmlFor="street">Straße und Hausnummer *</Label>
            <Input id="street" required value={form.street}
              onChange={(e) => update('street', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="postal_code">PLZ *</Label>
            <Input id="postal_code" required value={form.postal_code}
              onChange={(e) => update('postal_code', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="city">Ort *</Label>
            <Input id="city" required value={form.city}
              onChange={(e) => update('city', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="country">Land *</Label>
            <Input id="country" required value={form.country}
              onChange={(e) => update('country', e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="address_extra">Adresszusatz (optional)</Label>
            <Input id="address_extra" value={form.address_extra ?? ''}
              onChange={(e) => update('address_extra', e.target.value)} />
          </div>
        </div>
      </div>

      <div>
        <h3 className="font-semibold mb-3">3. Versandart</h3>
        <RadioGroup
          value={form.shipping_method}
          onValueChange={(v) => update('shipping_method', v as ShippingMethod)}
        >
          <div className="flex items-center gap-2">
            <RadioGroupItem value="standard" id="ship-standard" />
            <Label htmlFor="ship-standard">Standardversand</Label>
          </div>
          <div className="flex items-center gap-2">
            <RadioGroupItem value="pickup" id="ship-pickup" />
            <Label htmlFor="ship-pickup">Abholung</Label>
          </div>
        </RadioGroup>
      </div>

      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Wird gespeichert…' : 'Abo anlegen'}
      </Button>
    </form>
  );
}
