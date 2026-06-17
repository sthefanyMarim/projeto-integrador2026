import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/env.dart';
import '../../core/app_screen.dart';
import '../../core/online_only_guard.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/imagem_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';

class UsuarioFormScreen extends StatefulWidget {
  const UsuarioFormScreen({super.key, this.usuario});

  final UsuarioModel? usuario;

  bool get isEditing => usuario != null;

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  late final UsuarioService _service;
  late final ImagemService _imagemService;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _matriculaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _senhaCtrl;
  late String _tipo;
  late bool _ativo;
  bool _loading = false;
  bool _obscureSenha = true;
  XFile? _fotoFile;
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    final tokenService = TokenService();
    _service = UsuarioService(tokenService);
    _imagemService = ImagemService(tokenService);
    tokenService.getUserInfo().then((info) {
      if (mounted) setState(() => _isAdmin = info.tipo == 'ADMIN');
    });
    final u = widget.usuario;
    _nomeCtrl = TextEditingController(text: u?.nome ?? '');
    _matriculaCtrl = TextEditingController(text: u?.matricula ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _telefoneCtrl = TextEditingController(text: u?.telefone ?? '');
    _senhaCtrl = TextEditingController();
    _tipo = u?.tipo ?? 'TECNICO';
    _ativo = u?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _matriculaCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      _snack('O nome completo é obrigatório.');
      return;
    }
    if (_matriculaCtrl.text.trim().isEmpty) {
      _snack('A matrícula é obrigatória.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _snack('O e-mail é obrigatório.');
      return;
    }
    if (!widget.isEditing && _senhaCtrl.text.trim().length < 6) {
      _snack('A senha deve ter no mínimo 6 caracteres.');
      return;
    }

    final canProceed = await OnlineOnlyGuard.ensureServerReachable(
      context,
      actionLabel: widget.isEditing
          ? 'A edicao de usuarios'
          : 'O cadastro de usuarios',
    );
    if (!canProceed || !mounted) return;

    setState(() => _loading = true);

    final data = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'matricula': _matriculaCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telefone': _telefoneCtrl.text.trim().isEmpty
          ? null
          : _telefoneCtrl.text.trim(),
      'tipo': _tipo,
      if (widget.isEditing) 'ativo': _ativo,
    };

    final senha = _senhaCtrl.text.trim();
    if (senha.isNotEmpty) data['senha'] = senha;

    try {
      if (widget.isEditing) {
        await _service.atualizar(widget.usuario!.id, data);
      } else {
        await _service.criar(data);
      }

      if (_fotoFile != null) {
        await _imagemService.uploadFotoPerfil(_fotoFile!);
      }

      if (mounted) {
        AppFeedback.success(
          context,
          widget.isEditing
              ? 'Usuário atualizado com sucesso.'
              : 'Usuário cadastrado com sucesso.',
        );
        context.pop(true);
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

  Future<void> _pickFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _fotoFile = picked);
  }

  void _snack(String msg) => AppFeedback.warning(context, msg);

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
                      Text(
                        'Matrícula ${widget.usuario!.matricula}',
                        style: const TextStyle(
                          color: Color(0xFFA6A6A6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _sectionLabel('FOTO DE PERFIL (OPCIONAL)'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _pickFoto,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Alterar foto',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPG ou PNG, máx 2MB',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('DADOS PESSOAIS'),
                    const SizedBox(height: 10),
                    _fieldLabel('Nome Completo *'),
                    const SizedBox(height: 6),
                    _buildTextField(_nomeCtrl, 'Ex: João da Silva'),
                    const SizedBox(height: 14),
                    _fieldLabel('E-mail'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _emailCtrl,
                      'usuario@acad.ufsm.br',
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Telefone'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _telefoneCtrl,
                      '(55) 99999-9999',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Matrícula *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _matriculaCtrl,
                      '202412345',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('PERFIL DE ACESSO'),
                    const SizedBox(height: 10),
                    const Text(
                      'Nesta fase, alteracoes de perfil e status exigem conexao com o servidor.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isAdmin == false && widget.isEditing)
                      _buildRoleReadOnly()
                    else ...[
                      _buildRoleCard(
                        value: 'TECNICO',
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF5DADE2),
                        label: 'Técnico / Bolsista',
                        description: 'Acessa visitas e relatórios',
                      ),
                      const SizedBox(height: 8),
                      _buildRoleCard(
                        value: 'ADMIN',
                        icon: Icons.star_outline,
                        iconColor: const Color(0xFF00AE56),
                        label: 'Administrador',
                        description: 'Acessa gestão de usuários',
                      ),
                    ],
                    const SizedBox(height: 24),

                    _fieldLabel('senha:'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _senhaCtrl,
                      widget.isEditing ? '••••••' : 'Mínimo 6 caracteres',
                      obscureText: _obscureSenha,
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureSenha = !_obscureSenha),
                        child: Icon(
                          _obscureSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (widget.isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Deixe em branco para manter a senha atual',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    if (widget.isEditing && _isAdmin == true) ...[
                      _sectionLabel('STATUS DA CONTA'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
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
                                    'Conta Ativa',
                                    style: TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _ativo
                                        ? 'Usuário pode fazer login no sistema'
                                        : 'Usuário está bloqueado',
                                    style: const TextStyle(
                                      color: Color(0xFFA6A6A6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _ativo,
                              onChanged: (v) => setState(() => _ativo = v),
                              activeTrackColor: const Color(0xFF00AE56),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

  Widget _buildAvatar() {
    if (_fotoFile != null) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
          image: DecorationImage(
            image: FileImage(File(_fotoFile!.path)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final fotoUrl = widget.usuario?.fotoUrl;
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFAED6F1), width: 1.5),
          image: DecorationImage(
            image: NetworkImage(Env.rewriteMediaUrl(fotoUrl)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFD6EAF8),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFAED6F1), width: 1.5),
      ),
      child: const Icon(Icons.person, color: Color(0xFF5DADE2), size: 38),
    );
  }

  Widget _buildRoleReadOnly() {
    final isTecnico = _tipo == 'TECNICO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isTecnico ? Icons.person_outline : Icons.star_outline,
            size: 20,
            color: isTecnico
                ? const Color(0xFF5DADE2)
                : const Color(0xFF00AE56),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTecnico ? 'Técnico / Bolsista' : 'Administrador',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'O perfil de acesso não pode ser alterado aqui',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String description,
  }) {
    final isSelected = _tipo == value;
    return GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    widget.isEditing ? 'Editar Usuário' : 'Novo Usuário',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isEditing
                        ? 'Altere os dados do técnico ou bolsista'
                        : 'Cadastre um novo técnico ou administrador',
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
                        widget.isEditing ? 'Salvar Alterações' : 'Cadastrar',
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
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Container(
      height: 48,
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
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
        style: const TextStyle(color: Color(0xFF111111), fontSize: 13),
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
