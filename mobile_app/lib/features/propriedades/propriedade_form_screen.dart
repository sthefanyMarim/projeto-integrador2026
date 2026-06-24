import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/app_screen.dart';
import '../../core/form_validators.dart';
import '../../core/online_only_guard.dart';
import '../../data/models/propriedade_model.dart';
import '../../data/services/propriedade_service.dart';
import '../../data/services/token_service.dart';
import '../visita/visita_form_options.dart';
import 'map_picker_screen.dart';

class PropriedadeFormScreen extends StatefulWidget {
  const PropriedadeFormScreen({super.key, this.propriedade});

  final PropriedadeModel? propriedade;

  bool get isEditing => propriedade != null;

  @override
  State<PropriedadeFormScreen> createState() => _PropriedadeFormScreenState();
}

class _PropriedadeFormScreenState extends State<PropriedadeFormScreen> {
  static const _estados = [
    ['AC', 'Acre'],
    ['AL', 'Alagoas'],
    ['AP', 'Amapá'],
    ['AM', 'Amazonas'],
    ['BA', 'Bahia'],
    ['CE', 'Ceará'],
    ['DF', 'Distrito Federal'],
    ['ES', 'Espírito Santo'],
    ['GO', 'Goiás'],
    ['MA', 'Maranhão'],
    ['MT', 'Mato Grosso'],
    ['MS', 'Mato Grosso do Sul'],
    ['MG', 'Minas Gerais'],
    ['PA', 'Pará'],
    ['PB', 'Paraíba'],
    ['PR', 'Paraná'],
    ['PE', 'Pernambuco'],
    ['PI', 'Piauí'],
    ['RJ', 'Rio de Janeiro'],
    ['RN', 'Rio Grande do Norte'],
    ['RS', 'Rio Grande do Sul'],
    ['RO', 'Rondônia'],
    ['RR', 'Roraima'],
    ['SC', 'Santa Catarina'],
    ['SP', 'São Paulo'],
    ['SE', 'Sergipe'],
    ['TO', 'Tocantins'],
  ];

  static const _stateNameToAbbr = {
    'Acre': 'AC',
    'Alagoas': 'AL',
    'Amapá': 'AP',
    'Amazonas': 'AM',
    'Bahia': 'BA',
    'Ceará': 'CE',
    'Distrito Federal': 'DF',
    'Espírito Santo': 'ES',
    'Goiás': 'GO',
    'Maranhão': 'MA',
    'Mato Grosso': 'MT',
    'Mato Grosso do Sul': 'MS',
    'Minas Gerais': 'MG',
    'Pará': 'PA',
    'Paraíba': 'PB',
    'Paraná': 'PR',
    'Pernambuco': 'PE',
    'Piauí': 'PI',
    'Rio de Janeiro': 'RJ',
    'Rio Grande do Norte': 'RN',
    'Rio Grande do Sul': 'RS',
    'Rondônia': 'RO',
    'Roraima': 'RR',
    'Santa Catarina': 'SC',
    'São Paulo': 'SP',
    'Sergipe': 'SE',
    'Tocantins': 'TO',
  };

  late final PropriedadeService _service;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _nomeProprietarioCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _complementoCtrl;
  late final TextEditingController _municipioCtrl;
  String? _selectedEstado;
  String? _selectedTipoProducao;
  late bool _ativa;
  double? _latitude;
  double? _longitude;
  bool _loading = false;
  bool _geocodingLoading = false;

  @override
  void initState() {
    super.initState();
    _service = PropriedadeService(TokenService());
    final p = widget.propriedade;
    _nomeCtrl = TextEditingController(text: p?.nome ?? '');
    _nomeProprietarioCtrl = TextEditingController(
      text: p?.nomeProprietario ?? '',
    );
    _telefoneCtrl = TextEditingController(text: p?.telefone ?? '');
    _enderecoCtrl = TextEditingController(text: p?.endereco ?? '');
    _complementoCtrl = TextEditingController();
    _municipioCtrl = TextEditingController(text: p?.municipio ?? '');
    _selectedEstado = p?.estado?.isNotEmpty == true ? p!.estado : null;
    _selectedTipoProducao = knownOptionValue(tipoProducaoOptions, p?.tipoProducao);
    _ativa = p?.ativa ?? true;
    _latitude = p?.latitude;
    _longitude = p?.longitude;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _nomeProprietarioCtrl.dispose();
    _telefoneCtrl.dispose();
    _enderecoCtrl.dispose();
    _complementoCtrl.dispose();
    _municipioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomeProprietarioCtrl.text.trim().isEmpty) {
      AppFeedback.warning(context, 'O nome do responsável é obrigatório.');
      return;
    }
    if (_nomeCtrl.text.trim().isEmpty) {
      AppFeedback.warning(context, 'O nome da propriedade é obrigatório.');
      return;
    }
    final telefone = _telefoneCtrl.text.trim();
    if (telefone.isEmpty) {
      AppFeedback.warning(context, 'O telefone de contato é obrigatório.');
      return;
    }
    if (!telefoneRegex.hasMatch(telefone)) {
      AppFeedback.warning(
        context,
        'Telefone inválido. Use o formato (55) 99999-9999 ou (55) 9999-9999.',
      );
      return;
    }

    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: widget.isEditing
          ? 'A edição de propriedades'
          : 'O cadastro de propriedades',
    );
    if (!canProceed || !mounted) return;

    setState(() => _loading = true);

    final endereco = _enderecoCtrl.text.trim();
    final complemento = _complementoCtrl.text.trim();
    final enderecoFinal = endereco.isEmpty
        ? null
        : complemento.isEmpty
            ? endereco
            : '$endereco — $complemento';

    final data = {
      'nome': _nomeCtrl.text.trim(),
      'nomeProprietario': _nomeProprietarioCtrl.text.trim(),
      'telefone': telefone,
      'endereco': enderecoFinal,
      'municipio': _municipioCtrl.text.trim().isEmpty
          ? null
          : _municipioCtrl.text.trim(),
      'estado': _selectedEstado,
      'tipoProducao': _selectedTipoProducao,
      'latitude': _latitude,
      'longitude': _longitude,
      'ativa': _ativa,
    };

    try {
      if (widget.isEditing) {
        await _service.atualizar(widget.propriedade!.id, data);
        if (mounted) {
          AppFeedback.success(context, 'Propriedade atualizada com sucesso.');
          context.pop(true);
        }
      } else {
        await _service.criar(data);
        if (mounted) {
          AppFeedback.success(context, 'Propriedade cadastrada com sucesso.');
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        await AppFeedback.apiError(
          context,
          e,
          title: widget.isEditing ? 'Erro ao salvar' : 'Erro ao cadastrar',
          fallback: 'Não foi possível salvar as informações.',
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    final initial = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : null;

    final result = await Navigator.of(context, rootNavigator: true)
        .push<LatLng>(
          MaterialPageRoute(builder: (_) => MapPickerScreen(initial: initial)),
        );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _geocodingLoading = true;
      });
      await _reverseGeocode(result.latitude, result.longitude);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final dio = Dio();
      dio.options.headers['User-Agent'] =
          'PoliVisitas/1.0 (com.ufsm.polivisitas)';
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'format': 'json'},
      );
      dio.close();

      if (!mounted) return;

      final address =
          response.data['address'] as Map<String, dynamic>? ?? {};

      final road = address['road'] as String?;
      final houseNumber = address['house_number'] as String?;
      final suburb = address['suburb'] as String?;
      final city = address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['county'] as String?;
      final stateName = address['state'] as String? ?? '';
      final stateAbbr = _stateNameToAbbr[stateName];

      String endereco = '';
      if (road != null) {
        endereco = road;
        if (houseNumber != null) endereco += ', $houseNumber';
      } else if (suburb != null) {
        endereco = suburb;
      }

      setState(() {
        if (endereco.isNotEmpty) _enderecoCtrl.text = endereco;
        if (city != null) _municipioCtrl.text = city;
        if (stateAbbr != null) _selectedEstado = stateAbbr;
        _geocodingLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _geocodingLoading = false);
    }
  }

  void _pickEstado() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecionar Estado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _estados.length,
                  itemBuilder: (_, i) {
                    final abbr = _estados[i][0];
                    final nome = _estados[i][1];
                    final isSelected = _selectedEstado == abbr;
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedEstado = abbr);
                        Navigator.of(ctx).pop();
                      },
                      leading: SizedBox(
                        width: 32,
                        child: Text(
                          abbr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF444444),
                          ),
                        ),
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF111111),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                      dense: true,
                    );
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(ctx).padding.bottom + 16,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: true,
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isEditing) ...[
                      Row(
                        children: [
                          const Text(
                            'ID #',
                            style: TextStyle(
                              color: Color(0xFFA6A6A6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.propriedade!.id}',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    _sectionLabel('DADOS DO FEIRANTE'),
                    const SizedBox(height: 8),
                    _fieldLabel('Nome do Responsável *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _nomeProprietarioCtrl,
                      'Ex: João da Silva',
                      maxLength: 150,
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Telefone de Contato *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _telefoneCtrl,
                      '(55) 99999-9999',
                      keyboardType: TextInputType.phone,
                      maxLength: 15,
                      inputFormatters: [TelefoneInputFormatter()],
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('DADOS DA PROPRIEDADE'),
                    const SizedBox(height: 8),
                    _fieldLabel('Nome da Propriedade *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _nomeCtrl,
                      'Ex: Sítio Santa Rosa',
                      maxLength: 150,
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Endereço / Localização'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _enderecoCtrl,
                      'Estrada Municipal, km 12',
                      maxLength: 255,
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel('Complemento'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _complementoCtrl,
                      'Ex: próximo ao açude, portão verde...',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Município'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                _municipioCtrl,
                                'Santa Maria',
                                maxLength: 100,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Estado'),
                              const SizedBox(height: 6),
                              _buildEstadoSelector(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Tipo de Produção'),
                    const SizedBox(height: 6),
                    _buildTipoProducaoSelector(),
                    const SizedBox(height: 24),
                    _sectionLabel('LOCALIZAÇÃO GPS (OPCIONAL)'),
                    const SizedBox(height: 8),
                    _buildGpsRow(context),
                    if (_geocodingLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primary,
                        backgroundColor: Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Buscando endereço...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _sectionLabel('STATUS'),
                    const SizedBox(height: 8),
                    const Text(
                      'Nesta fase, ativar ou inativar propriedades exige conexão com o servidor.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Propriedade Ativa',
                                  style: TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isEditing
                                      ? 'Técnicos podem agendar visitas'
                                      : 'Técnicos podem agendar visitas para esta unidade',
                                  style: const TextStyle(
                                    color: Color(0xFFA6A6A6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _ativa,
                            onChanged: (v) => setState(() => _ativa = v),
                            activeTrackColor: const Color(0xFF00AE56),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              InkWell(
                onTap: _loading ? null : () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEditing
                        ? 'Editar Propriedade'
                        : 'Nova Propriedade',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isEditing
                        ? 'Altere os dados da unidade produtora'
                        : 'Cadastre uma nova unidade produtora',
                    style: const TextStyle(
                      color: Color(0xFFCCF2D9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : () => context.pop(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00AE56),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Salvar Alterações'
                            : 'Cadastrar Propriedade',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          counterText: '',
        ),
        style: const TextStyle(color: Color(0xFF111111), fontSize: 13),
      ),
    );
  }

  Widget _buildEstadoSelector() {
    return GestureDetector(
      onTap: _pickEstado,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedEstado ?? 'UF',
                style: TextStyle(
                  color: _selectedEstado != null
                      ? const Color(0xFF111111)
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _pickTipoProducao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecionar Tipo de Produção',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tipoProducaoOptions.length,
                  itemBuilder: (_, i) {
                    final option = tipoProducaoOptions[i];
                    final isSelected = _selectedTipoProducao == option.value;
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedTipoProducao = option.value);
                        Navigator.of(ctx).pop();
                      },
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF111111),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                      dense: true,
                    );
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(ctx).padding.bottom + 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipoProducaoSelector() {
    return GestureDetector(
      onTap: _pickTipoProducao,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedTipoProducao != null
                    ? optionLabel(tipoProducaoOptions, _selectedTipoProducao)
                    : 'Selecionar...',
                style: TextStyle(
                  color: _selectedTipoProducao != null
                      ? const Color(0xFF111111)
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsRow(BuildContext context) {
    final hasCoords = _latitude != null && _longitude != null;

    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasCoords
                ? const Color(0xFF00AE56).withValues(alpha: 0.4)
                : const Color(0xFFE0E0E0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              hasCoords ? Icons.location_on : Icons.location_on_outlined,
              size: 20,
              color: const Color(0xFF00AE56),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCoords ? 'Localização definida' : 'Escolher no mapa',
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCoords
                        ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                        : 'Toque para abrir o mapa',
                    style: TextStyle(
                      color: hasCoords
                          ? const Color(0xFF006A18)
                          : const Color(0xFFA6A6A6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (hasCoords)
              GestureDetector(
                onTap: () => setState(() {
                  _latitude = null;
                  _longitude = null;
                }),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 18, color: Color(0xFFA6A6A6)),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA6A6A6),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
