class FormValidators {
  FormValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _otpRegExp = RegExp(r'^\d{6}$');
  static final RegExp _pseudoRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final RegExp _dateIsoRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Validation Email (format RFC 5322)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L’adresse email est obligatoire';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Veuillez saisir une adresse email valide';
    }
    return null;
  }

  /// Validation Mot de passe
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < minLength) {
      return 'Le mot de passe doit contenir au moins $minLength caractères';
    }
    return null;
  }

  /// Confirmation Mot de passe
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != originalPassword) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Validation Nom / Prénom
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    if (value.trim().length < minLength) {
      return 'Le nom doit contenir au moins $minLength caractères';
    }
    return null;
  }

  /// Validation Pseudo
  static String? validatePseudo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Pseudo optionnel
    }
    final trimmed = value.trim();
    if (!_pseudoRegExp.hasMatch(trimmed)) {
      return 'Pseudo entre 3 et 20 caractères alphanumériques (a-z, 0-9, _)';
    }
    return null;
  }

  /// Validation Code OTP à 6 chiffres
  static String? validateOtpCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code à 6 chiffres est requis';
    }
    final trimmed = value.trim();
    if (!_otpRegExp.hasMatch(trimmed)) {
      return 'Le code doit contenir exactement 6 chiffres';
    }
    return null;
  }

  /// Validation Date de naissance (YYYY-MM-DD)
  static String? validateDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La date de naissance est obligatoire';
    }
    final trimmed = value.trim();
    if (!_dateIsoRegExp.hasMatch(trimmed)) {
      return 'Format de date invalide (AAAA-MM-JJ)';
    }

    try {
      final dob = DateTime.parse(trimmed);
      final now = DateTime.now();
      if (dob.isAfter(now)) {
        return 'La date ne peut pas être dans le futur';
      }
      final ageYears = now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1);
      if (ageYears < 13) {
        return 'Vous devez avoir au moins 13 ans pour utiliser Voyago 🦜';
      }
      if (ageYears > 120) {
        return 'Date de naissance invalide';
      }
    } catch (_) {
      return 'Date de naissance invalide';
    }

    return null;
  }

  /// Validation Champ requis générique
  static String? validateRequired(String? value, [String fieldLabel = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel est obligatoire';
    }
    return null;
  }

  /// Validation Destination de voyage
  static String? validateDestination(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir une destination';
    }
    if (value.trim().length < 2) {
      return 'Destination trop courte (min 2 caractères)';
    }
    return null;
  }
}
