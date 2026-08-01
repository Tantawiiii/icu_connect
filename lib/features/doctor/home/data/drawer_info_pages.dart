import 'package:icu_connect/core/constants/app_texts.dart';

class DrawerInfoSection {
  const DrawerInfoSection({this.heading, required this.body});

  final String? heading;
  final String body;
}

class DrawerInfoPage {
  const DrawerInfoPage({required this.title, required this.sections});

  final String title;
  final List<DrawerInfoSection> sections;
}

/// Static drawer info pages (About, Help, Privacy, etc.).
class DrawerInfoPages {
  DrawerInfoPages._();

  static const aboutUs = DrawerInfoPage(
    title: AppTexts.aboutUs,
    sections: [
      DrawerInfoSection(
        heading: 'What is ICU Connect?',
        body:
            'ICU Connect is a mobile platform built for intensive care teams. '
            'It helps doctors and nurses document admissions, track vitals and labs, '
            'manage bed occupancy, and keep clinical information organized in one place.',
      ),
      DrawerInfoSection(
        heading: 'Our mission',
        body:
            'We aim to make ICU handovers clearer and safer. By reducing scattered '
            'notes and missed updates, teams can focus on patient care with better '
            'visibility across shifts and hospital units.',
      ),
      DrawerInfoSection(
        heading: 'Who it is for',
        body:
            'ICU Connect is designed for ICU doctors, residents, and hospital staff '
            'who need fast access to patient status, admission details, and structured '
            'clinical documentation during rounds and handovers.',
      ),
    ],
  );

  static const helpAndSupport = DrawerInfoPage(
    title: AppTexts.helpAndSupport,
    sections: [
      DrawerInfoSection(
        heading: 'Getting started',
        body:
            'After login, open a hospital from your home list to view bed maps, '
            'admitted patients, and discharged outcomes. Tap a bed to open admission '
            'details or assign a new patient to an empty bed.',
      ),
      DrawerInfoSection(
        heading: 'Admission details',
        body:
            'Each admission includes clinical notes, medications, vitals, labs, '
            'imaging, treatment plans, and activity history. Use the edit controls '
            'on each section to add or update records. Pull down to refresh data.',
      ),
      DrawerInfoSection(
        heading: 'Vitals & labs tables',
        body:
            'Readings are grouped by date in columns. Tap the pencil icon to add a '
            'new date column, or tap an existing date or value to edit that column. '
            'Title names stay fixed while you scroll through reading columns.',
      ),
      DrawerInfoSection(
        heading: 'Need more help?',
        body:
            'If something is not working as expected, use Report a Problem from the '
            'menu and describe what happened. Include the screen name and steps if '
            'possible so we can assist you faster.',
      ),
    ],
  );

  static const privacyPolicy = DrawerInfoPage(
    title: AppTexts.privacyPolicy,
    sections: [
      DrawerInfoSection(
        heading: 'Data we handle',
        body:
            'ICU Connect processes patient and clinical data required for ICU '
            'workflow. This may include names, admission details, vitals, lab results, '
            'notes, and related medical documentation entered by authorized staff.',
      ),
      DrawerInfoSection(
        heading: 'How data is used',
        body:
            'Information is used only to support patient care, hospital operations, '
            'and audit trails within your institution. We do not sell patient data. '
            'Access is limited to authenticated users approved by your hospital.',
      ),
      DrawerInfoSection(
        heading: 'Security',
        body:
            'Connections use encrypted transport. Sessions require login credentials '
            'and can be revoked on logout. Always lock your device and avoid sharing '
            'your account with others.',
      ),
      DrawerInfoSection(
        heading: 'Your responsibilities',
        body:
            'Use ICU Connect in line with your hospital policies and applicable '
            'healthcare privacy regulations. Do not export or share patient information '
            'outside approved channels.',
      ),
    ],
  );

  static const termsOfUse = DrawerInfoPage(
    title: AppTexts.termsOfUse,
    sections: [
      DrawerInfoSection(
        heading: 'Acceptable use',
        body:
            'ICU Connect is a clinical support tool. It does not replace professional '
            'medical judgment. You are responsible for verifying all information before '
            'making care decisions.',
      ),
      DrawerInfoSection(
        heading: 'Account access',
        body:
            'Accounts are personal and must be approved by your hospital administrator. '
            'You must keep your login details confidential and notify your admin if '
            'you suspect unauthorized access.',
      ),
      DrawerInfoSection(
        heading: 'Accuracy of records',
        body:
            'Data entered into the app should reflect the best available clinical '
            'information at the time of documentation. Correct errors promptly when '
            'they are identified.',
      ),
      DrawerInfoSection(
        heading: 'Service availability',
        body:
            'We strive for reliable uptime but cannot guarantee uninterrupted access. '
            'Have a backup workflow for critical situations when connectivity or the '
            'service is unavailable.',
      ),
    ],
  );

  static const reportProblem = DrawerInfoPage(
    title: AppTexts.reportProblem,
    sections: [
      DrawerInfoSection(
        heading: 'Before you report',
        body:
            'Check your internet connection and try refreshing the screen. Many issues '
            'are resolved after a pull-to-refresh or by logging out and back in.',
      ),
      DrawerInfoSection(
        heading: 'What to include',
        body:
            'Describe what you were trying to do, what you expected, and what happened '
            'instead. Mention the hospital, patient or admission ID if relevant, and '
            'the approximate time of the issue.',
      ),
      DrawerInfoSection(
        heading: 'How to reach us',
        body:
            'Contact your hospital ICU Connect administrator first for access or '
            'permission issues. For app bugs or technical problems, call us at '
            '01156587388 or email your support team or IT department with screenshots '
            'when possible.',
      ),
      DrawerInfoSection(
        heading: 'Urgent clinical matters',
        body:
            'ICU Connect is not an emergency channel. For urgent patient care, follow '
            'your unit\'s escalation protocols and use direct clinical communication '
            'methods immediately.',
      ),
    ],
  );
}
