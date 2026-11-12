import '../domain/model/equipment.dart';
import '../domain/model/site.dart';
import '../infrastructure/assemblers/assets_assembler.dart';
import '../infrastructure/assets_api.dart';

/// Application service of the Assets context: equipment and site of an assignment.
/// Keeps the last copy read so the screens can show it again without connection.
class AssetsService {
  AssetsService._();

  static final AssetsService instance = AssetsService._();

  final AssetsApi _api = AssetsApi();
  final Map<int, Equipment> _equipment = {};
  final Map<int, Site> _sites = {};

  Equipment? cachedEquipment(int id) => _equipment[id];
  Site? cachedSite(int id) => _sites[id];

  Future<Equipment> equipment(int id) async {
    final equipment = AssetsAssembler.toEquipment(await _api.getEquipment(id));
    _equipment[id] = equipment;
    return equipment;
  }

  Future<Site> site(int id) async {
    final site = AssetsAssembler.toSite(await _api.getSite(id));
    _sites[id] = site;
    return site;
  }

  void clear() {
    _equipment.clear();
    _sites.clear();
  }
}
