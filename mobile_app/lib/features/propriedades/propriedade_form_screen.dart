import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/api_error_dialog.dart';
import '../../core/app_colors.dart';
import '../../core/app_screen.dart';
import '../../data/models/propriedade_model.dart';
import '../../data/services/propriedade_service.dart';
import '../../data/services/token_service.dart';
import 'map_picker_screen.dart';

class PropriedadeFormScreen extends StatefulWidget {
  const PropriedadeFormScreen({super.key, this.propriedade});

  final PropriedadeModel? propriedade;

  bool get isEditing => propriedade != null;

  @override
  State<PropriedadeFormScreen> createState() => _PropriedadeFormScreenState();
}

class _PropriedadeFormScreenState extends State<PropriedadeFormScreen> {
  late final PropriedadeService _service;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _nomeProprietarioCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _enderecoCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _estadoCtrl;
  late final TextEditingController _tipoProducaoCtrl;
  late bool _ativa;
  double? _latitude;
  double? _longitude;
  bool _loading = false;

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
    _municipioCtrl = TextEditingController(text: p?.municipio ?? '');
    _estadoCtrl = TextEditingController(text: p?.estado ?? '');
    _tipoProducaoCtrl = TextEditingController(text: p?.tipoProducao ?? '');
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
    _municipioCtrl.dispose();
    _estadoCtrl.dispose();
    _tipoProducaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomeProprietarioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O nome do responsÃ¡vel Ã© obrigatÃ³rio.'),
        ),
      );
      return;
    }
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome da propriedade Ã© obrigatÃ³rio.')),
      );
      return;
    }

    setState(() => _loading = true);

    final data = {
      'nome': _nomeCtrl.text.trim(),
      'nomeProprietario': _nomeProprietarioCtrl.text.trim(),
      'telefone': _telefoneCtrl.text.trim().isEmpty
          ? null
          : _telefoneCtrl.text.trim(),
      'endereco': _enderecoCtrl.text.trim().isEmpty
          ? null
          : _enderecoCtrl.text.trim(),
      'municipio': _municipioCtrl.text.trim().isEmpty
          ? null
          : _municipioCtrl.text.trim(),
      'estado': _estadoCtrl.text.trim().isEmpty
          ? null
          : _estadoCtrl.text.trim(),
      'tipoProducao': _tipoProducaoCtrl.text.trim().isEmpty
          ? null
          : _tipoProducaoCtrl.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'ativa': _ativa,
    };

    try {
      if (widget.isEditing) {
        await _service.atualizar(widget.propriedade!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriedade atualizada com sucesso.'),
            ),
          );
          context.pop(true);
        }
      } else {
        await _service.criar(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriedade cadastrada com sucesso.'),
            ),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        await ApiErrorDialog.show(
          context,
          e,
          title: widget.isEditing ? 'Erro ao salvar' : 'Erro ao cadastrar',
          fallback: 'NÃ£o foi possÃ­vel salvar as informaÃ§Ãµes.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: false,
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
                    _fieldLabel('Nome do ResponsÃ¡vel *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _nomeProprietarioCtrl,
                      'Ex: JoÃ£o da Silva',
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Telefone de Contato'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _telefoneCtrl,
                      '(55) 99999-9999',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('DADOS DA PROPRIEDADE'),
                    const SizedBox(height: 8),
                    _fieldLabel('Nome da Propriedade *'),
                    const SizedBox(height: 6),
                    _buildTextField(_nomeCtrl, 'Ex: SÃ­tio Santa Rosa'),
                    const SizedBox(height: 16),
                    _fieldLabel('EndereÃ§o / LocalizaÃ§Ã£o'),
                    const SizedBox(height: 6),
                    _buildTextField(_enderecoCtrl, 'Estrada Municipal, km 12'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('MunicÃ­pio'),
                              const SizedBox(height: 6),
                              _buildTextField(_municipioCtrl, 'Santa Maria'),
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
                              _buildTextField(
                                _estadoCtrl,
                                'RS',
                                maxLength: 2,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Tipo de ProduÃ§Ã£o'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _tipoProducaoCtrl,
                      'Ex: OrgÃ¢nico, Convencional, AgroecolÃ³gico...',
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('LOCALIZAÃ‡ÃƒO GPS (OPCIONAL)'),
                    const SizedBox(height: 8),
                    _buildGpsRow(context),
                    const SizedBox(height: 24),
                    _sectionLabel('STATUS'),
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
                                      ? 'TÃ©cnicos podem agendar visitas'
                                      : 'TÃ©cnicos podem agendar visitas para esta unidade',
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
                            ? 'Salvar AlteraÃ§Ãµes'
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
      });
    }
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
                    hasCoords ? 'LocalizaÃ§Ã£o definida' : 'Escolher no mapa',
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
                        : 'Toque para abrir o Google Maps',
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
