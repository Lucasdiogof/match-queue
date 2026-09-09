import 'package:fifa_queue/features/legal/data/legal_content_en.dart';
import 'package:fifa_queue/features/legal/data/legal_content_es.dart';
import 'package:fifa_queue/features/legal/data/legal_content_pt.dart';
import 'package:fifa_queue/features/legal/domain/legal_document.dart';
import 'package:flutter/widgets.dart';

LegalDocument resolvePrivacyPolicy(Locale locale) =>
    switch (locale.languageCode) {
      'en' => kPrivacyPolicyEn,
      'es' => kPrivacyPolicyEs,
      _ => kPrivacyPolicyPt,
    };

LegalDocument resolveTermsOfUse(Locale locale) => switch (locale.languageCode) {
  'en' => kTermsOfUseEn,
  'es' => kTermsOfUseEs,
  _ => kTermsOfUsePt,
};
