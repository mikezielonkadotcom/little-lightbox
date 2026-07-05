<?php
/**
 * Uninstall cleanup for This Little Lightbox of Mine.
 *
 * @package MZV_Lightbox
 */

defined( 'WP_UNINSTALL_PLUGIN' ) || exit;

$updater_file = __DIR__ . '/includes/um-updater.php';

if ( ! class_exists( '\\UM\\PluginUpdater\\Updater' ) && file_exists( $updater_file ) ) {
	require_once $updater_file;
}

if ( class_exists( '\\UM\\PluginUpdater\\Updater' ) ) {
	\UM\PluginUpdater\Updater::cleanup( 'little-lightbox' );
}
