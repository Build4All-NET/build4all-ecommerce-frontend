enum PlanCode { FREE, PRO_HOSTEDB, DEDICATED }

PlanCode planCodeFromString(String? v) {
  switch ((v ?? '').toUpperCase().trim()) {
    case 'FREE':
      return PlanCode.FREE;
    case 'PRO_HOSTEDB':
      return PlanCode.PRO_HOSTEDB;
    case 'DEDICATED':
      return PlanCode.DEDICATED;
    default:
      return PlanCode.FREE;
  }
}

String planCodeToString(PlanCode code) {
  switch (code) {
    case PlanCode.FREE:
      return 'FREE';
    case PlanCode.PRO_HOSTEDB:
      return 'PRO_HOSTEDB';
    case PlanCode.DEDICATED:
      return 'DEDICATED';
  }
}
