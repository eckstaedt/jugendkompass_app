import 'package:jugendkompass_app/core/localization/app_translations.dart';

/// Translates German strings from database to current language
class StringTranslator {
  // Map of German strings to translation keys
  static const Map<String, String> _germanToKeyMap = {
    // Common UI strings
    'Startseite': 'home',
    'Entdecken': 'explore',
    'Podcasts': 'podcasts',
    'Videos': 'videos',
    'Einstellungen': 'settings',
    'Suchen': 'search',
    'Keine Ergebnisse gefunden': 'no_results',
    'Laden...': 'loading',
    'Fehler': 'error',
    'Erneut versuchen': 'try_again',
    'Schließen': 'close',
    'Zurück': 'back',
    
    // Date strings
    'Heute': 'today',
    'Gestern': 'yesterday',
    
    // Content types
    'Tagesvers': 'daily_verse',
    'Täglicher Impuls': 'daily_impulse',
    'Neueste Inhalte': 'latest_content',
    'Kürzliche Inhalte': 'recent_content',
    'Artikel': 'articles',
    'Alle Ausgaben': 'all_editions',
    'Keine Artikel gefunden': 'no_articles_found',
    'Artikel in dieser Ausgabe': 'articles_in_edition',
    'Vorwort anhören': 'listen_to_foreword',
    'Ausgabe anhören': 'listen_to_edition',
    'PDF herunterladen': 'download_pdf',
    
    // Settings
    'Sprache': 'language',
    'Benachrichtigungen': 'notifications',
    'Push-Benachrichtigungen erhalten': 'enable_notifications',
    'Dark Mode': 'dark_mode',
    'Dunkles Theme verwenden': 'use_dark_theme',
    'Profil': 'profile',
    'Profil bearbeiten': 'edit_profile',
    'Name': 'name',
    'E-Mail': 'email',
    'Speichern': 'save',
    'Abbrechen': 'cancel',
    'Konto löschen': 'delete_account',
    'Alle Daten löschen': 'delete_all_data',
    'Bist du sicher?': 'are_you_sure',
    'Alle Daten wurden gelöscht': 'all_data_deleted',
    'Abmelden': 'logout',
    'Anmelden': 'login',
    'Willkommen': 'welcome',
    'Dein täglicher Begleiter für dein Glaubensleben.': 'your_daily_companion',
    'Wie heißt du?': 'what_is_your_name',
    'Weiter': 'continue_button',
    
    // Playback
    'Jetzt läuft': 'now_playing',
    'Unbekannter Titel': 'unknown_title',
    'Abspielen': 'play',
    'Pausieren': 'pause',
    'Nächstes Lied': 'skip_next',
    'Vorheriges Lied': 'skip_previous',
    'Lesezeit': 'reading_time',
    'Min': 'min',
    
    // Empty states
    'Keine Verse verfügbar': 'no_verses_available',
    'Keine Impulse verfügbar': 'no_impulses',
    'No Content Available': 'no_content_available',
    'No More Content': 'no_more_content',
    'Latest Content': 'latest_content',
    'Recent Content': 'recent_content',
    'Error': 'error',
    
    // Search & Settings UI
    'Suche in der ganzen App...': 'search_in_app',
    'EINSTELLUNGEN': 'settings_header',
    'VERS DES TAGES': 'verses_section',
    'Favoriten': 'favorites',
    'Vers': 'verse',
    'Verse': 'verses_plural',
    'SAMMLUNGEN': 'collections_section',
    'MEINE INHALTE': 'my_content_section',
    'WEITERE OPTIONEN': 'more_options_section',
    'Über die App': 'about_app',
    'Datenschutz': 'privacy',
    'Nutzungsbedingungen': 'terms',
    'Wähle deine Sprache': 'choose_language',
    
    // Collection & Shop
    'Deine Sammlung': 'my_collection',
    'Element': 'item',
    'Elemente': 'items',
    'Shop': 'shop',
    'Bald verfügbar': 'coming_soon',
    
    // Danger Zone
    'GEFAHRENBEREICH': 'danger_zone',
    'Daten löschen': 'delete_data',
    'Löscht alle deine lokalen Daten und setzt die App zurück.': 'delete_data_description',
    'Daten löschen?': 'delete_data_dialog_title',
    'Möchtest du wirklich alle deine Daten löschen? Diese Aktion kann nicht rückgängig gemacht werden.\n\nFolgende Daten werden gelöscht:\n• Dein Name und Einstellungen\n• Alle Favoriten\n• Bibelleseplan-Fortschritt\n• Dark Mode Einstellung': 'delete_data_confirmation',
    'Löschen': 'delete_action',
    'Fehler beim Löschen': 'delete_error',
    
    // Kiosk
    'Keine Magazine verfügbar': 'no_magazines',
    'Schau später noch einmal vorbei': 'check_back_later',
    'Lade Magazine...': 'loading_magazines',
    'Fehler beim Laden der Magazine': 'error_loading_magazines',
    
    // Podcast
    'Keine Podcasts verfügbar': 'no_podcasts',
    'Es sind noch keine Podcast-Episoden vorhanden.': 'no_podcast_episodes',
    'Lade Podcasts...': 'loading_podcasts',
    'Fehler beim Laden der Podcasts': 'error_loading_podcasts',
    
    // Video
    'Keine Videos gefunden': 'no_videos_found',
    'Versuche eine andere Suche': 'try_different_search',
    'Fehler: ': 'error_prefix',
    
    // Additional screens
    'Inhalte': 'content_header',
    'Alle': 'all_filter',
    'Audio': 'audio_type',
    'Video': 'video_type',
    'Keine favorisierten Verse': 'no_favorite_verses',
    'Like den Vers des Tages um ihn hier zu speichern': 'like_verse_to_save',
    'Keine Artikel verfügbar': 'no_articles_available',
    'Impuls': 'impulse_type',
    'Ausgabe': 'edition_type',
    
    'Videos suchen...': 'search_videos',
    'Der Shop wird bald verfügbar sein!': 'shop_coming_soon_title',
    'Bis dahin kannst du dich zurücklehnen und dich auf neue Angebote freuen.': 'shop_coming_soon_subtitle',
    'Favorisierte Verse': 'favorite_verses_title',
    'Vers entfernen': 'remove_verse',
    'Diesen Vers aus Favoriten entfernen?': 'remove_verse_confirmation',
    'Alle löschen': 'delete_all',
    'Sammlung leeren?': 'clear_collection',
    'Möchtest du wirklich alle Inhalte aus deiner Sammlung löschen?': 'clear_collection_confirmation',
    'Cover nicht verfügbar': 'no_cover_available',
    'Keine Audios verfügbar': 'no_audios_available',
    'Es sind noch keine Audio-Inhalte vorhanden.': 'no_audio_content',
    'Lade Audios...': 'loading_audios',
    'Der Jugendkompass': 'app_title',
    'Los geht\'s 🚀': 'lets_go',
    'Aktuell gibt es keine Impulse zum Anzeigen.': 'no_impulses_message',
    'Lade Impulse...': 'loading_impulses',
    'Fehler beim Laden der Impulse': 'error_loading_impulses',
    'Ungültige YouTube URL': 'invalid_youtube_url',
    'Fehler beim Laden des Videos': 'error_loading_video',
    'Keine Favoriten': 'no_favorites',
    'Markiere Inhalte als Favoriten, um sie hier zu sehen.': 'mark_as_favorite',
    'Fehler beim Abspielen': 'error_playing',
    'Audio nicht gefunden': 'audio_not_found',
    'PDF konnte nicht geöffnet werden': 'pdf_not_opened',
    'Fehler beim Öffnen des PDFs': 'error_opening_pdf',
    'ALLE FOLGEN': 'all_episodes',
    'Deine Sammlung ist leer': 'empty_collection_title',
    'Speichern Sie Inhalte mit dem Speichersymbol': 'save_content_with_button',
    'Lesen': 'read',
    'Impulse': 'impulses',
    'Audios': 'audios',
    'Kein Audio ausgewählt': 'no_audio_selected',
    'Für Dich': 'for_you',
    'Wonach suchst du?': 'what_are_you_looking_for',
    'Keine Inhalte gefunden': 'no_content_found',
    'Versuche einen anderen Filter oder Suchbegriff': 'try_different_filter',
    'Weiter anhören': 'continue_listening',
    'Artikel anhören': 'listen_to_article',
    'Lade Inhalt...': 'loading_content',
    'Lade Video...': 'loading_video',
    'Inhalt nicht gefunden': 'content_not_found',
    'Video nicht gefunden': 'video_not_found',
    'Inhalt': 'content',
    'Bild erfolgreich hochgeladen': 'image_uploaded',
    'Fehler beim Hochladen': 'error_uploading',
    'Fehler beim Auswählen des Bildes': 'error_selecting_image',
    'Bitte gib einen Namen mit mindestens 2 Zeichen ein': 'name_too_short',
    'Profil gespeichert': 'profile_saved',
    'Fehler beim Speichern': 'error_saving',
    'Fehler beim Laden': 'error_loading',
    'Lade Videos...': 'loading_videos',
    'Pause': 'pause',
    'Wiedergabegeschwindigkeit': 'playback_speed',
    'Player': 'player',
    'Suche': 'search',
    'Rückgängig': 'undo',
  };

  /// Translates a German string to the current language
  /// If the string is not found in the map, returns the original string
  static String translate(String germanString, AppLanguage language) {
    if (germanString.isEmpty) return germanString;
    
    // Check if this is a known German string
    final translationKey = _germanToKeyMap[germanString];
    if (translationKey == null) {
      return germanString; // Not found, return original
    }
    
    // Get the translation
    final translations = Translations(language);
    return translations.get(translationKey);
  }

  /// Auto-translates any German string in the database
  /// This is called automatically when displaying content from the database
  static String autoTranslate(String? text, AppLanguage language) {
    if (text == null || text.isEmpty) return text ?? '';
    
    // Try to translate if it's a known German string
    return translate(text, language);
  }
}
