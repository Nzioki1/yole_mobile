import '../models/insurance_product.dart';

/// Static insurance product catalog for offline demo
const List<InsuranceProduct> kInsuranceProducts = [
  InsuranceProduct(
    id: 'health_hosp',
    nameFr: 'Santé hospitalisation',
    subtitleEn: 'Health Hospitalization',
    descriptionFr:
        'Couvre les frais d\'hospitalisation en cas de maladie ou d\'accident jusqu\'à 500 000 CDF par an.',
    claimCapMinor: 50000000, // 500,000 CDF
    iconAsset: 'assets/icons/insurance_health.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.MONTHLY,
      fixedMinor: 250000, // 2,500 CDF
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'death_funeral',
    nameFr: 'Décès & funérailles',
    subtitleEn: 'Death & Funeral',
    descriptionFr:
        'Verse un capital aux bénéficiaires pour couvrir les frais funéraires jusqu\'à 1 000 000 CDF.',
    claimCapMinor: 100000000, // 1,000,000 CDF
    iconAsset: 'assets/icons/insurance_death.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.PERCENT,
      percentBps: 30, // 0.3%
      deductFrom: DeductFrom.SEND,
    ),
  ),
  InsuranceProduct(
    id: 'accident',
    nameFr: 'Accident',
    subtitleEn: 'Accident',
    descriptionFr:
        'Indemnise les blessures corporelles dues à un accident jusqu\'à 300 000 CDF.',
    claimCapMinor: 30000000, // 300,000 CDF
    iconAsset: 'assets/icons/insurance_accident.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.PER_TXN,
      fixedMinor: 100000, // 1,000 CDF
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'credit_protection',
    nameFr: 'Protection crédit',
    subtitleEn: 'Credit Protection',
    descriptionFr:
        'Rembourse votre prêt en cas de décès, d\'invalidité ou de perte d\'emploi.',
    claimCapMinor: 0, // Varies by loan
    iconAsset: 'assets/icons/insurance_credit.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.PERCENT,
      percentBps: 100, // 1.0%
      deductFrom: DeductFrom.BOTH,
    ),
  ),
  InsuranceProduct(
    id: 'phone_device',
    nameFr: 'Téléphone & appareil',
    subtitleEn: 'Phone & Device',
    descriptionFr:
        'Répare ou remplace votre téléphone en cas de vol, casse ou panne jusqu\'à 200 000 CDF.',
    claimCapMinor: 20000000, // 200,000 CDF
    iconAsset: 'assets/icons/insurance_phone.svg',
    defaults: InsurancePremiumDefaults(
      premiumMode: PremiumMode.FIXED,
      fixedSchedule: FixedSchedule.MONTHLY,
      fixedMinor: 300000, // 3,000 CDF
      deductFrom: DeductFrom.BILL,
    ),
  ),
];
