import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/l10n/app_localizations.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openTelegram() async {
    // TODO: Заменить на реальный Telegram канал/бот
    const telegramUrl = 'https://t.me/your_support_bot';
    final uri = Uri.parse(telegramUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      logger.e('Could not launch $telegramUrl', error: e);
    }
  }

  Future<void> _openEmail() async {
    // TODO: Заменить на реальный email
    const email = 'support@example.com';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Поддержка',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      logger.e('Could not launch email', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.support),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.contactUs,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.contactUsDescription,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.telegram, 
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Telegram'),
                  subtitle: Text(AppLocalizations.of(context)!.writeInTelegram),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openTelegram,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(AppLocalizations.of(context)!.writeByEmail),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openEmail,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.faq,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    context,
                    AppLocalizations.of(context)!.faqCancelOrder,
                    AppLocalizations.of(context)!.faqCancelOrderAnswer,
                  ),
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    context,
                    AppLocalizations.of(context)!.faqChangeAddress,
                    AppLocalizations.of(context)!.faqChangeAddressAnswer,
                  ),
                  const SizedBox(height: 12),
                  _buildFAQItem(
                    context,
                    AppLocalizations.of(context)!.faqPaymentMethods,
                    AppLocalizations.of(context)!.faqPaymentMethodsAnswer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

