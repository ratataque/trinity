import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trinity/stores/user_store.dart';
import 'package:trinity/screens/login_page.dart';
import 'package:trinity/screens/home_page.dart';
import 'package:trinity/utils/api/user.dart';
import 'package:trinity/type/user.dart';
import 'package:crypto/crypto.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool _isDark = true;
  Future<User?>? _userFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Méthode pour charger ou rafraîchir les données utilisateur
  void _loadUserData() {
    setState(() {
      _userFuture = UserApi().getUserDetails().then((user) {
        _currentUser = user;
        return user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStore = Provider.of<UserStore>(context);

    return Theme(
      data: _isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Votre compte"),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView(
              children: [
                _SingleSection(
                  title: "Paramètres de l'application",
                  children: [
                    _CustomListTile(
                      title: "Mode Sombre",
                      icon: Icons.dark_mode_outlined,
                      trailing: Switch(
                        value: _isDark,
                        onChanged: (value) {
                          setState(() {
                            _isDark = value;
                          });
                        },
                      ),
                    ),
                    const _CustomListTile(
                      title: "Notifications",
                      icon: Icons.notifications_none_rounded,
                    ),
                  ],
                ),
                if (userStore.isAuthenticated) ...[
                  _SingleSection(
                    title: "Profil utilisateur",
                    children: [
                      FutureBuilder<User?>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text("Erreur: ${snapshot.error}"));
                          } else if (snapshot.hasData) {
                            final user = snapshot.data;
                            return Column(
                              children: [
                                _CustomListTileWithValue(
                                  title: "Nom",
                                  value: user?.lastName ?? "Non renseigné",
                                  icon: Icons.person_outline_rounded,
                                ),
                                _CustomListTileWithValue(
                                  title: "Prénom",
                                  value: user?.firstName ?? "Non renseigné",
                                  icon: Icons.message_outlined,
                                ),
                                _CustomListTileWithValue(
                                  title: "Email",
                                  value: user?.email ?? "Non renseigné",
                                  icon: Icons.email_outlined,
                                ),
                                _CustomListTileWithValue(
                                  title: "Numéro de téléphone",
                                  value: user?.phoneNumber ?? "Non renseigné",
                                  icon: Icons.phone_outlined,
                                ),
                                _CustomListTileWithValue(
                                  title: "Adresse",
                                  value: user?.address ?? "Non renseigné",
                                  icon: Icons.home_outlined,
                                ),
                                _CustomListTileWithValue(
                                  title: "Ville + Code postal",
                                  value: user?.city != null
                                      ? "${user?.city?.name ?? 'Non renseigné'} ${user?.city?.postalCode ?? 'Non renseigné'}"
                                      : "Non renseigné",
                                  icon: Icons.location_city_outlined,
                                ),
                              ],
                            );
                          } else {
                            return const Center(child: Text("Aucune donnée disponible"));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Utilisation de la variable _currentUser qui est mise à jour par le FutureBuilder
                            showDialog(
                              context: context,
                              builder: (context) => UserInfoEditModal(
                                currentUser: _currentUser,
                                onUserUpdated: _loadUserData,
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Modifier"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => ChangePasswordModal(
                                onPasswordChanged: _loadUserData,
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_outline),
                          label: const Text("Mot de passe"),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
                _SingleSection(
                  children: [
                    const _CustomListTile(
                      title: "À propos",
                      icon: Icons.info_outline_rounded,
                    ),
                    _CustomListTile(
                      title: userStore.isAuthenticated
                          ? "Se déconnecter"
                          : "Se connecter",
                      icon: userStore.isAuthenticated ? Icons.exit_to_app_rounded : Icons.login_rounded,
                      onTap: () {
                        if (userStore.isAuthenticated) {
                          userStore.resetUser();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                                (route) => false,
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Classes d'utilitaires
class _CustomListTileWithValue extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _CustomListTileWithValue({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _CustomListTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SingleSection({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ...children,
        const Divider(),
      ],
    );
  }
}

// Modal de changement de mot de passe
class ChangePasswordModal extends StatefulWidget {
  final VoidCallback? onPasswordChanged;

  const ChangePasswordModal({super.key, this.onPasswordChanged});

  @override
  _ChangePasswordModalState createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Changer le mot de passe"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField("Mot de passe actuel", _currentPasswordController),
            _buildPasswordField("Nouveau mot de passe", _newPasswordController),
            _buildPasswordField("Confirmer le mot de passe", _confirmPasswordController),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePassword,
          child: const Text("Modifier"),
        ),
      ],
    );
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final hashedCurrentPassword = hashPassword(_currentPasswordController.text);
        final hashedNewPassword = hashPassword(_newPasswordController.text);

        await UserApi().updatePassword(
          hashedCurrentPassword,
          hashedNewPassword,
        );

        // Appel du callback pour rafraîchir les données si nécessaire
        if (widget.onPasswordChanged != null) {
          widget.onPasswordChanged!();
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mot de passe mis à jour")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
    );
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}

// Modal de modification des informations utilisateur
class UserInfoEditModal extends StatefulWidget {
  final User? currentUser;
  final VoidCallback? onUserUpdated;

  const UserInfoEditModal({super.key, this.currentUser, this.onUserUpdated});

  @override
  _UserInfoEditModalState createState() => _UserInfoEditModalState();
}

class _UserInfoEditModalState extends State<UserInfoEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.currentUser?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.currentUser?.lastName ?? '');
    _emailController = TextEditingController(text: widget.currentUser?.email ?? '');
    _phoneController = TextEditingController(text: widget.currentUser?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.currentUser?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifier les informations"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Prénom", _firstNameController),
              _buildTextField("Nom", _lastNameController),
              _buildTextField("Email", _emailController),
              _buildTextField("Téléphone", _phoneController),
              _buildTextField("Adresse", _addressController),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUserInfo,
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }

  Future<void> _updateUserInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedUser = {
          "id": widget.currentUser?.id,
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "email": _emailController.text,
          "phoneNumber": _phoneController.text,
          "address": _addressController.text,
        };

        await UserApi().updateUser(updatedUser);

        if (widget.onUserUpdated != null) {
          widget.onUserUpdated!();
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Informations mises à jour")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur : ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
    );
  }
}