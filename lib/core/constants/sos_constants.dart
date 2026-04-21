/// Same copy as backend `SOS_NO_AMBULANCE_DRIVER_MESSAGE` / `patient.service` (patient-facing).
// ignore: constant_identifier_names — aligned with backend export name.
const String SOS_NO_AMBULANCE_DRIVER_MESSAGE =
    "We can't find any ambulance driver near you.";

class SosConstants {
  SosConstants._();

  static const String noAmbulanceDriverMessage =
      SOS_NO_AMBULANCE_DRIVER_MESSAGE;

  static const String retrySearchingMessage =
      'Searching for a nearby ambulance again…';
}
