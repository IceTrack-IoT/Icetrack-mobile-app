enum EquipmentHealth { normal, warning, critical, offline }

class PastIntervention {
  const PastIntervention({required this.date, required this.type, required this.summary});

  final String date;
  final String type;
  final String summary;
}

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.model,
    required this.siteName,
    required this.temperature,
    required this.threshold,
    required this.powerKw,
    required this.energyKwh,
    required this.isDoorOpen,
    required this.health,
    required this.lastReading,
    required this.readings,
    required this.history,
  });

  final String id;
  final String name;
  final String model;
  final String siteName;
  final double? temperature;
  final double threshold;
  final double powerKw;
  final double energyKwh;
  final bool isDoorOpen;
  final EquipmentHealth health;
  final String lastReading;
  final List<double> readings;
  final List<PastIntervention> history;

  bool get isOutOfRange => temperature != null && temperature! > threshold;
}

class EquipmentAlert {
  const EquipmentAlert({
    required this.equipmentId,
    required this.health,
    required this.detail,
  });

  final String equipmentId;
  final EquipmentHealth health;
  final String detail;
}
