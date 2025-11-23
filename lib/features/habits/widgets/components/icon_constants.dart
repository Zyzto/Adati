import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../main.dart';

/// Shared icon list for habit and tag forms
class IconConstants {
  static final List<IconData> commonIcons = [
    // Basic & Common
    Icons.label,
    Icons.category,
    Icons.star,
    Icons.favorite,
    Icons.home,
    
    // Work & Education
    Icons.work,
    Icons.school,
    Icons.business,
    Icons.apartment,
    
    // Health & Fitness
    Icons.fitness_center,
    Icons.directions_walk,
    Icons.directions_run,
    Icons.bike_scooter,
    Icons.directions_bike,
    Icons.pool,
    Icons.self_improvement,
    Icons.airline_seat_flat,
    Icons.health_and_safety,
    Icons.spa,
    
    // Sports & Activities
    Icons.sports_soccer,
    Icons.surfing,
    Icons.skateboarding,
    Icons.snowboarding,
    Icons.sailing,
    Icons.kayaking,
    Icons.hiking,
    Icons.forest,
    Icons.terrain,
    Icons.rocket_launch,
    
    // Food & Dining
    Icons.local_dining,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.coffee,
    
    // Entertainment
    Icons.music_note,
    Icons.movie,
    Icons.games,
    Icons.book,
    Icons.library_books,
    Icons.library_music,
    Icons.theater_comedy,
    Icons.video_library,
    Icons.menu_book,
    Icons.auto_stories,
    Icons.newspaper,
    Icons.article,
    
    // Nature & Animals
    Icons.nature,
    Icons.pets,
    Icons.beach_access,
    
    // Daily Life
    Icons.bedtime,
    Icons.water_drop,
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.shopping_basket,
    
    // Travel & Transportation
    Icons.directions_car,
    Icons.flight,
    Icons.flight_takeoff,
    Icons.flight_land,
    Icons.hotel,
    Icons.train,
    Icons.directions_bus,
    Icons.directions_subway,
    Icons.directions_boat,
    Icons.local_taxi,
    Icons.map,
    Icons.place,
    Icons.location_on,
    Icons.navigation,
    Icons.explore,
    Icons.travel_explore,
    
    // Finance
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.payments,
    Icons.credit_card,
    Icons.receipt,
    Icons.attach_money,
    Icons.trending_up,
    Icons.trending_down,
    Icons.bar_chart,
    Icons.pie_chart,
    Icons.show_chart,
    Icons.analytics,
    
    // Technology
    Icons.computer,
    Icons.laptop,
    Icons.phone_android,
    Icons.phone_iphone,
    Icons.tablet,
    Icons.watch,
    Icons.headphones,
    Icons.speaker,
    Icons.tv,
    Icons.camera_alt,
    Icons.videocam,
    Icons.mic,
    Icons.code,
    Icons.calculate,
    
    // Media & Creative
    Icons.palette,
    Icons.brush,
    Icons.color_lens,
    Icons.image,
    Icons.photo_library,
    Icons.photo_camera,
    
    // Documents & Notes
    Icons.description,
    Icons.note,
    Icons.note_add,
    Icons.edit_note,
    Icons.draw,
    Icons.create,
    Icons.edit,
    Icons.border_color,
    Icons.format_paint,
    Icons.text_snippet,
    Icons.sticky_note_2,
    Icons.attach_file,
    Icons.link,
    Icons.insert_link,
    
    // Tools & Building
    Icons.build,
    Icons.construction,
    Icons.handyman,
    Icons.auto_fix_high,
    Icons.auto_fix_normal,
    Icons.electric_bolt,
    Icons.flash_on,
    Icons.lightbulb,
    Icons.light_mode,
    Icons.dark_mode,
    Icons.wb_sunny,
    Icons.nightlight,
    Icons.bed,
    Icons.hotel_class,
    
    // Places & Services
    Icons.store,
    Icons.storefront,
    Icons.local_gas_station,
    Icons.local_pharmacy,
    Icons.local_hospital,
    Icons.local_police,
    Icons.local_fire_department,
    Icons.local_library,
    Icons.local_post_office,
    Icons.local_parking,
    Icons.local_atm,
    
    // Social & People
    Icons.account_circle,
    Icons.person,
    Icons.person_add,
    Icons.group,
    Icons.groups,
    Icons.people,
    Icons.people_outline,
    Icons.supervisor_account,
    Icons.family_restroom,
    Icons.volunteer_activism,
    Icons.celebration,
    
    // Achievements & Rewards
    Icons.badge,
    Icons.workspace_premium,
    Icons.emoji_events,
    Icons.military_tech,
    Icons.stars,
    Icons.workspace_premium_outlined,
    Icons.card_giftcard,
    Icons.card_membership,
    Icons.loyalty,
    Icons.redeem,
    Icons.local_offer,
    Icons.local_activity,
    
    // Tech & Connectivity
    Icons.qr_code,
    Icons.qr_code_scanner,
    Icons.qr_code_2,
    Icons.nfc,
    Icons.bluetooth,
    Icons.wifi,
    Icons.signal_wifi_4_bar,
    Icons.signal_cellular_4_bar,
    Icons.battery_full,
    Icons.power,
    Icons.power_off,
    Icons.power_settings_new,
    
    // Settings & Security
    Icons.settings,
    Icons.settings_applications,
    Icons.tune,
    Icons.build_circle,
    Icons.admin_panel_settings,
    Icons.security,
    Icons.lock,
    Icons.lock_open,
    Icons.vpn_key,
    Icons.password,
    Icons.fingerprint,
    Icons.face,
    Icons.face_retouching_natural,
    Icons.verified,
    Icons.verified_user,
    Icons.shield,
    Icons.privacy_tip,
    
    // Actions
    Icons.check_circle,
    Icons.check,
    Icons.add_circle,
    Icons.add,
    Icons.remove_circle,
    Icons.remove,
    Icons.delete,
    Icons.delete_forever,
    Icons.restore,
    Icons.restore_from_trash,
    Icons.archive,
    Icons.unarchive,
    Icons.download,
    Icons.upload,
    Icons.report,
    Icons.flag,
    Icons.block,
    Icons.cancel,
    Icons.close,
    
    // Cloud & Sync
    Icons.cloud_upload,
    Icons.cloud_download,
    Icons.cloud,
    Icons.cloud_done,
    Icons.cloud_off,
    Icons.cloud_sync,
    Icons.backup,
    Icons.sync,
    Icons.sync_alt,
    Icons.refresh,
    Icons.autorenew,
    Icons.cached,
    Icons.update,
    Icons.system_update,
    Icons.install_mobile,
    Icons.install_desktop,
    Icons.get_app,
    Icons.publish,
    Icons.file_upload,
    Icons.file_download,
    
    // Files & Folders
    Icons.folder,
    Icons.folder_open,
    Icons.folder_shared,
    Icons.insert_drive_file,
    Icons.drive_file_rename_outline,
    Icons.drive_file_move,
    Icons.drive_file_move_outline,
    Icons.drive_file_move_rtl,
    Icons.create_new_folder,
    Icons.folder_copy,
    Icons.folder_delete,
    Icons.folder_zip,
    Icons.folder_special,
    Icons.folder_off,
    Icons.content_copy,
    Icons.content_cut,
    Icons.content_paste,
    Icons.copy_all,
    Icons.cut,
    Icons.paste,
    
    // Language & Communication
    Icons.public,
    Icons.language,
    Icons.translate,
    Icons.g_translate,
    Icons.currency_exchange,
    Icons.confirmation_number,
    Icons.compass_calibration,
    Icons.explore_off,
  ];
  
  /// Available colors for forms (700 shade for better contrast)
  static final List<Color> availableColors = [
    Colors.deepPurple[700]!,
    Colors.blue[700]!,
    Colors.green[700]!,
    Colors.orange[700]!,
    Colors.red[700]!,
    Colors.pink[700]!,
    Colors.teal[700]!,
    Colors.indigo[700]!,
    Colors.amber[700]!,
    Colors.cyan[700]!,
    Colors.lime[700]!,
    Colors.brown[700]!,
  ];

  /// Predefined units for measurable tracking
  static const List<String> predefinedUnits = [
    'minutes',
    'hours',
    'km',
    'miles',
    'steps',
    'count',
    'times',
    'pages',
    'glasses',
    'cups',
    'liters',
    'calories',
    'kg',
    'lbs',
    'reps',
    'sets',
  ];

  /// Map of icon codePoints to translation key names
  static final Map<int, String> _iconTranslationKeys = {
    // Basic & Common
    Icons.label.codePoint: 'icon_label_keywords',
    Icons.category.codePoint: 'icon_category_keywords',
    Icons.star.codePoint: 'icon_star_keywords',
    Icons.favorite.codePoint: 'icon_favorite_keywords',
    Icons.home.codePoint: 'icon_home_keywords',
    
    // Work & Education
    Icons.work.codePoint: 'icon_work_keywords',
    Icons.school.codePoint: 'icon_school_keywords',
    Icons.business.codePoint: 'icon_business_keywords',
    Icons.apartment.codePoint: 'icon_apartment_keywords',
    
    // Health & Fitness
    Icons.fitness_center.codePoint: 'icon_fitness_center_keywords',
    Icons.directions_walk.codePoint: 'icon_directions_walk_keywords',
    Icons.directions_run.codePoint: 'icon_directions_run_keywords',
    Icons.bike_scooter.codePoint: 'icon_bike_scooter_keywords',
    Icons.directions_bike.codePoint: 'icon_directions_bike_keywords',
    Icons.pool.codePoint: 'icon_pool_keywords',
    Icons.self_improvement.codePoint: 'icon_self_improvement_keywords',
    Icons.airline_seat_flat.codePoint: 'icon_airline_seat_flat_keywords',
    Icons.health_and_safety.codePoint: 'icon_health_and_safety_keywords',
    Icons.spa.codePoint: 'icon_spa_keywords',
    
    // Sports & Activities
    Icons.sports_soccer.codePoint: 'icon_sports_soccer_keywords',
    Icons.surfing.codePoint: 'icon_surfing_keywords',
    Icons.skateboarding.codePoint: 'icon_skateboarding_keywords',
    Icons.snowboarding.codePoint: 'icon_snowboarding_keywords',
    Icons.sailing.codePoint: 'icon_sailing_keywords',
    Icons.kayaking.codePoint: 'icon_kayaking_keywords',
    Icons.hiking.codePoint: 'icon_hiking_keywords',
    Icons.forest.codePoint: 'icon_forest_keywords',
    Icons.terrain.codePoint: 'icon_terrain_keywords',
    Icons.rocket_launch.codePoint: 'icon_rocket_launch_keywords',
    
    // Food & Dining
    Icons.local_dining.codePoint: 'icon_local_dining_keywords',
    Icons.restaurant.codePoint: 'icon_restaurant_keywords',
    Icons.local_cafe.codePoint: 'icon_local_cafe_keywords',
    Icons.local_bar.codePoint: 'icon_local_bar_keywords',
    Icons.coffee.codePoint: 'icon_coffee_keywords',
    
    // Entertainment
    Icons.music_note.codePoint: 'icon_music_note_keywords',
    Icons.movie.codePoint: 'icon_movie_keywords',
    Icons.games.codePoint: 'icon_games_keywords',
    Icons.book.codePoint: 'icon_book_keywords',
    Icons.library_books.codePoint: 'icon_library_books_keywords',
    Icons.library_music.codePoint: 'icon_library_music_keywords',
    Icons.theater_comedy.codePoint: 'icon_theater_comedy_keywords',
    Icons.video_library.codePoint: 'icon_video_library_keywords',
    Icons.menu_book.codePoint: 'icon_menu_book_keywords',
    Icons.auto_stories.codePoint: 'icon_auto_stories_keywords',
    Icons.newspaper.codePoint: 'icon_newspaper_keywords',
    Icons.article.codePoint: 'icon_article_keywords',
    
    // Nature & Animals
    Icons.nature.codePoint: 'icon_nature_keywords',
    Icons.pets.codePoint: 'icon_pets_keywords',
    Icons.beach_access.codePoint: 'icon_beach_access_keywords',
    
    // Daily Life
    Icons.bedtime.codePoint: 'icon_bedtime_keywords',
    Icons.water_drop.codePoint: 'icon_water_drop_keywords',
    Icons.shopping_cart.codePoint: 'icon_shopping_cart_keywords',
    Icons.shopping_bag.codePoint: 'icon_shopping_bag_keywords',
    Icons.shopping_basket.codePoint: 'icon_shopping_basket_keywords',
    
    // Travel & Transportation
    Icons.directions_car.codePoint: 'icon_directions_car_keywords',
    Icons.flight.codePoint: 'icon_flight_keywords',
    Icons.flight_takeoff.codePoint: 'icon_flight_takeoff_keywords',
    Icons.flight_land.codePoint: 'icon_flight_land_keywords',
    Icons.hotel.codePoint: 'icon_hotel_keywords',
    Icons.train.codePoint: 'icon_train_keywords',
    Icons.directions_bus.codePoint: 'icon_directions_bus_keywords',
    Icons.directions_subway.codePoint: 'icon_directions_subway_keywords',
    Icons.directions_boat.codePoint: 'icon_directions_boat_keywords',
    Icons.local_taxi.codePoint: 'icon_local_taxi_keywords',
    Icons.map.codePoint: 'icon_map_keywords',
    Icons.place.codePoint: 'icon_place_keywords',
    Icons.location_on.codePoint: 'icon_location_on_keywords',
    Icons.navigation.codePoint: 'icon_navigation_keywords',
    Icons.explore.codePoint: 'icon_explore_keywords',
    Icons.travel_explore.codePoint: 'icon_travel_explore_keywords',
    
    // Finance
    Icons.account_balance.codePoint: 'icon_account_balance_keywords',
    Icons.account_balance_wallet.codePoint: 'icon_account_balance_wallet_keywords',
    Icons.savings.codePoint: 'icon_savings_keywords',
    Icons.payments.codePoint: 'icon_payments_keywords',
    Icons.credit_card.codePoint: 'icon_credit_card_keywords',
    Icons.receipt.codePoint: 'icon_receipt_keywords',
    Icons.attach_money.codePoint: 'icon_attach_money_keywords',
    Icons.trending_up.codePoint: 'icon_trending_up_keywords',
    Icons.trending_down.codePoint: 'icon_trending_down_keywords',
    Icons.bar_chart.codePoint: 'icon_bar_chart_keywords',
    Icons.pie_chart.codePoint: 'icon_pie_chart_keywords',
    Icons.show_chart.codePoint: 'icon_show_chart_keywords',
    Icons.analytics.codePoint: 'icon_analytics_keywords',
    
    // Technology
    Icons.computer.codePoint: 'icon_computer_keywords',
    Icons.laptop.codePoint: 'icon_laptop_keywords',
    Icons.phone_android.codePoint: 'icon_phone_android_keywords',
    Icons.phone_iphone.codePoint: 'icon_phone_iphone_keywords',
    Icons.tablet.codePoint: 'icon_tablet_keywords',
    Icons.watch.codePoint: 'icon_watch_keywords',
    Icons.headphones.codePoint: 'icon_headphones_keywords',
    Icons.speaker.codePoint: 'icon_speaker_keywords',
    Icons.tv.codePoint: 'icon_tv_keywords',
    Icons.camera_alt.codePoint: 'icon_camera_alt_keywords',
    Icons.videocam.codePoint: 'icon_videocam_keywords',
    Icons.mic.codePoint: 'icon_mic_keywords',
    Icons.code.codePoint: 'icon_code_keywords',
    Icons.calculate.codePoint: 'icon_calculate_keywords',
    
    // Media & Creative
    Icons.palette.codePoint: 'icon_palette_keywords',
    Icons.brush.codePoint: 'icon_brush_keywords',
    Icons.color_lens.codePoint: 'icon_color_lens_keywords',
    Icons.image.codePoint: 'icon_image_keywords',
    Icons.photo_library.codePoint: 'icon_photo_library_keywords',
    Icons.photo_camera.codePoint: 'icon_photo_camera_keywords',
    
    // Documents & Notes
    Icons.description.codePoint: 'icon_description_keywords',
    Icons.note.codePoint: 'icon_note_keywords',
    Icons.note_add.codePoint: 'icon_note_add_keywords',
    Icons.edit_note.codePoint: 'icon_edit_note_keywords',
    Icons.draw.codePoint: 'icon_draw_keywords',
    Icons.create.codePoint: 'icon_create_keywords',
    Icons.edit.codePoint: 'icon_edit_keywords',
    Icons.border_color.codePoint: 'icon_border_color_keywords',
    Icons.format_paint.codePoint: 'icon_format_paint_keywords',
    Icons.text_snippet.codePoint: 'icon_text_snippet_keywords',
    Icons.sticky_note_2.codePoint: 'icon_sticky_note_2_keywords',
    Icons.attach_file.codePoint: 'icon_attach_file_keywords',
    Icons.link.codePoint: 'icon_link_keywords',
    Icons.insert_link.codePoint: 'icon_insert_link_keywords',
    
    // Tools & Building
    Icons.build.codePoint: 'icon_build_keywords',
    Icons.construction.codePoint: 'icon_construction_keywords',
    Icons.handyman.codePoint: 'icon_handyman_keywords',
    Icons.auto_fix_high.codePoint: 'icon_auto_fix_high_keywords',
    Icons.auto_fix_normal.codePoint: 'icon_auto_fix_normal_keywords',
    Icons.electric_bolt.codePoint: 'icon_electric_bolt_keywords',
    Icons.flash_on.codePoint: 'icon_flash_on_keywords',
    Icons.lightbulb.codePoint: 'icon_lightbulb_keywords',
    Icons.light_mode.codePoint: 'icon_light_mode_keywords',
    Icons.dark_mode.codePoint: 'icon_dark_mode_keywords',
    Icons.wb_sunny.codePoint: 'icon_wb_sunny_keywords',
    Icons.nightlight.codePoint: 'icon_nightlight_keywords',
    Icons.bed.codePoint: 'icon_bed_keywords',
    Icons.hotel_class.codePoint: 'icon_hotel_class_keywords',
    
    // Places & Services
    Icons.store.codePoint: 'icon_store_keywords',
    Icons.storefront.codePoint: 'icon_storefront_keywords',
    Icons.local_gas_station.codePoint: 'icon_local_gas_station_keywords',
    Icons.local_pharmacy.codePoint: 'icon_local_pharmacy_keywords',
    Icons.local_hospital.codePoint: 'icon_local_hospital_keywords',
    Icons.local_police.codePoint: 'icon_local_police_keywords',
    Icons.local_fire_department.codePoint: 'icon_local_fire_department_keywords',
    Icons.local_library.codePoint: 'icon_local_library_keywords',
    Icons.local_post_office.codePoint: 'icon_local_post_office_keywords',
    Icons.local_parking.codePoint: 'icon_local_parking_keywords',
    Icons.local_atm.codePoint: 'icon_local_atm_keywords',
    
    // Social & People
    Icons.account_circle.codePoint: 'icon_account_circle_keywords',
    Icons.person.codePoint: 'icon_person_keywords',
    Icons.person_add.codePoint: 'icon_person_add_keywords',
    Icons.group.codePoint: 'icon_group_keywords',
    Icons.groups.codePoint: 'icon_groups_keywords',
    Icons.people.codePoint: 'icon_people_keywords',
    Icons.people_outline.codePoint: 'icon_people_outline_keywords',
    Icons.supervisor_account.codePoint: 'icon_supervisor_account_keywords',
    Icons.family_restroom.codePoint: 'icon_family_restroom_keywords',
    Icons.volunteer_activism.codePoint: 'icon_volunteer_activism_keywords',
    Icons.celebration.codePoint: 'icon_celebration_keywords',
    
    // Achievements & Rewards
    Icons.badge.codePoint: 'icon_badge_keywords',
    Icons.workspace_premium.codePoint: 'icon_workspace_premium_keywords',
    Icons.emoji_events.codePoint: 'icon_emoji_events_keywords',
    Icons.military_tech.codePoint: 'icon_military_tech_keywords',
    Icons.stars.codePoint: 'icon_stars_keywords',
    Icons.workspace_premium_outlined.codePoint: 'icon_workspace_premium_outlined_keywords',
    Icons.card_giftcard.codePoint: 'icon_card_giftcard_keywords',
    Icons.card_membership.codePoint: 'icon_card_membership_keywords',
    Icons.loyalty.codePoint: 'icon_loyalty_keywords',
    Icons.redeem.codePoint: 'icon_redeem_keywords',
    Icons.local_offer.codePoint: 'icon_local_offer_keywords',
    Icons.local_activity.codePoint: 'icon_local_activity_keywords',
    
    // Tech & Connectivity
    Icons.qr_code.codePoint: 'icon_qr_code_keywords',
    Icons.qr_code_scanner.codePoint: 'icon_qr_code_scanner_keywords',
    Icons.qr_code_2.codePoint: 'icon_qr_code_2_keywords',
    Icons.nfc.codePoint: 'icon_nfc_keywords',
    Icons.bluetooth.codePoint: 'icon_bluetooth_keywords',
    Icons.wifi.codePoint: 'icon_wifi_keywords',
    Icons.signal_wifi_4_bar.codePoint: 'icon_signal_wifi_4_bar_keywords',
    Icons.signal_cellular_4_bar.codePoint: 'icon_signal_cellular_4_bar_keywords',
    Icons.battery_full.codePoint: 'icon_battery_full_keywords',
    Icons.power.codePoint: 'icon_power_keywords',
    Icons.power_off.codePoint: 'icon_power_off_keywords',
    Icons.power_settings_new.codePoint: 'icon_power_settings_new_keywords',
    
    // Settings & Security
    Icons.settings.codePoint: 'icon_settings_keywords',
    Icons.settings_applications.codePoint: 'icon_settings_applications_keywords',
    Icons.tune.codePoint: 'icon_tune_keywords',
    Icons.build_circle.codePoint: 'icon_build_circle_keywords',
    Icons.admin_panel_settings.codePoint: 'icon_admin_panel_settings_keywords',
    Icons.security.codePoint: 'icon_security_keywords',
    Icons.lock.codePoint: 'icon_lock_keywords',
    Icons.lock_open.codePoint: 'icon_lock_open_keywords',
    Icons.vpn_key.codePoint: 'icon_vpn_key_keywords',
    Icons.password.codePoint: 'icon_password_keywords',
    Icons.fingerprint.codePoint: 'icon_fingerprint_keywords',
    Icons.face.codePoint: 'icon_face_keywords',
    Icons.face_retouching_natural.codePoint: 'icon_face_retouching_natural_keywords',
    Icons.verified.codePoint: 'icon_verified_keywords',
    Icons.verified_user.codePoint: 'icon_verified_user_keywords',
    Icons.shield.codePoint: 'icon_shield_keywords',
    Icons.privacy_tip.codePoint: 'icon_privacy_tip_keywords',
    
    // Actions
    Icons.check_circle.codePoint: 'icon_check_circle_keywords',
    Icons.check.codePoint: 'icon_check_keywords',
    Icons.add_circle.codePoint: 'icon_add_circle_keywords',
    Icons.add.codePoint: 'icon_add_keywords',
    Icons.remove_circle.codePoint: 'icon_remove_circle_keywords',
    Icons.remove.codePoint: 'icon_remove_keywords',
    Icons.delete.codePoint: 'icon_delete_keywords',
    Icons.delete_forever.codePoint: 'icon_delete_forever_keywords',
    Icons.restore.codePoint: 'icon_restore_keywords',
    Icons.restore_from_trash.codePoint: 'icon_restore_from_trash_keywords',
    Icons.archive.codePoint: 'icon_archive_keywords',
    Icons.unarchive.codePoint: 'icon_unarchive_keywords',
    Icons.download.codePoint: 'icon_download_keywords',
    Icons.upload.codePoint: 'icon_upload_keywords',
    Icons.report.codePoint: 'icon_report_keywords',
    Icons.flag.codePoint: 'icon_flag_keywords',
    Icons.block.codePoint: 'icon_block_keywords',
    Icons.cancel.codePoint: 'icon_cancel_keywords',
    Icons.close.codePoint: 'icon_close_keywords',
    
    // Cloud & Sync
    Icons.cloud_upload.codePoint: 'icon_cloud_upload_keywords',
    Icons.cloud_download.codePoint: 'icon_cloud_download_keywords',
    Icons.cloud.codePoint: 'icon_cloud_keywords',
    Icons.cloud_done.codePoint: 'icon_cloud_done_keywords',
    Icons.cloud_off.codePoint: 'icon_cloud_off_keywords',
    Icons.cloud_sync.codePoint: 'icon_cloud_sync_keywords',
    Icons.backup.codePoint: 'icon_backup_keywords',
    Icons.sync.codePoint: 'icon_sync_keywords',
    Icons.sync_alt.codePoint: 'icon_sync_alt_keywords',
    Icons.refresh.codePoint: 'icon_refresh_keywords',
    Icons.autorenew.codePoint: 'icon_autorenew_keywords',
    Icons.cached.codePoint: 'icon_cached_keywords',
    Icons.update.codePoint: 'icon_update_keywords',
    Icons.system_update.codePoint: 'icon_system_update_keywords',
    Icons.install_mobile.codePoint: 'icon_install_mobile_keywords',
    Icons.install_desktop.codePoint: 'icon_install_desktop_keywords',
    Icons.get_app.codePoint: 'icon_get_app_keywords',
    Icons.publish.codePoint: 'icon_publish_keywords',
    Icons.file_upload.codePoint: 'icon_file_upload_keywords',
    Icons.file_download.codePoint: 'icon_file_download_keywords',
    
    // Files & Folders
    Icons.folder.codePoint: 'icon_folder_keywords',
    Icons.folder_open.codePoint: 'icon_folder_open_keywords',
    Icons.folder_shared.codePoint: 'icon_folder_shared_keywords',
    Icons.insert_drive_file.codePoint: 'icon_insert_drive_file_keywords',
    Icons.drive_file_rename_outline.codePoint: 'icon_drive_file_rename_outline_keywords',
    Icons.drive_file_move.codePoint: 'icon_drive_file_move_keywords',
    Icons.drive_file_move_outline.codePoint: 'icon_drive_file_move_outline_keywords',
    Icons.drive_file_move_rtl.codePoint: 'icon_drive_file_move_rtl_keywords',
    Icons.create_new_folder.codePoint: 'icon_create_new_folder_keywords',
    Icons.folder_copy.codePoint: 'icon_folder_copy_keywords',
    Icons.folder_delete.codePoint: 'icon_folder_delete_keywords',
    Icons.folder_zip.codePoint: 'icon_folder_zip_keywords',
    Icons.folder_special.codePoint: 'icon_folder_special_keywords',
    Icons.folder_off.codePoint: 'icon_folder_off_keywords',
    Icons.content_copy.codePoint: 'icon_content_copy_keywords',
    Icons.content_cut.codePoint: 'icon_content_cut_keywords',
    Icons.content_paste.codePoint: 'icon_content_paste_keywords',
    Icons.copy_all.codePoint: 'icon_copy_all_keywords',
    Icons.cut.codePoint: 'icon_cut_keywords',
    Icons.paste.codePoint: 'icon_paste_keywords',
    
    // Language & Communication
    Icons.public.codePoint: 'icon_public_keywords',
    Icons.language.codePoint: 'icon_language_keywords',
    Icons.translate.codePoint: 'icon_translate_keywords',
    Icons.g_translate.codePoint: 'icon_g_translate_keywords',
    Icons.currency_exchange.codePoint: 'icon_currency_exchange_keywords',
    Icons.confirmation_number.codePoint: 'icon_confirmation_number_keywords',
    Icons.compass_calibration.codePoint: 'icon_compass_calibration_keywords',
    Icons.explore_off.codePoint: 'icon_explore_off_keywords',
  };

  /// Cache for loaded translations
  static final Map<String, Map<String, dynamic>> _translationsCache = {};
  static final Map<String, Future<Map<String, dynamic>>> _loadingFutures = {};
  
  /// Returns searchable keywords for an icon from translations
  static List<String> getSearchKeywords(IconData icon, BuildContext? context) {
    final translationKey = _iconTranslationKeys[icon.codePoint];
    if (translationKey == null) return [];
    
    // If no context, try using navigatorKey
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) return [];
    
    try {
      final easyLocalization = EasyLocalization.of(ctx);
      if (easyLocalization == null) return [];
      
      final locale = easyLocalization.locale;
      final localeCode = locale.languageCode;
      
      // Return from cache if available
      if (_translationsCache.containsKey(localeCode)) {
        final translations = _translationsCache[localeCode];
        if (translations != null && translations.containsKey(translationKey)) {
          final keywords = translations[translationKey];
          if (keywords is List) {
            return List<String>.from(keywords);
          }
        }
      } else {
        // Start loading translations asynchronously (for future calls)
        if (!_loadingFutures.containsKey(localeCode)) {
          _loadingFutures[localeCode] = rootBundle
              .loadString('assets/translations/$localeCode.json')
              .then((jsonString) {
            final translations = jsonDecode(jsonString) as Map<String, dynamic>;
            _translationsCache[localeCode] = translations;
            return translations;
          });
        }
      }
    } catch (e) {
      // Fallback to empty list if translation fails
    }
    
    return [];
  }

  /// Checks if an icon matches the search query
  static bool matchesSearch(IconData icon, String query, BuildContext? context) {
    if (query.isEmpty) return true;
    final keywords = getSearchKeywords(icon, context);
    final lowerQuery = query.toLowerCase();
    return keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
  }
}

