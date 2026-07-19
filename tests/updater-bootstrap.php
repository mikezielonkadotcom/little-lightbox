<?php

$source = file_get_contents( dirname( __DIR__ ) . '/little-lightbox.php' );

if ( false === $source ) {
	fwrite( STDERR, "Could not read little-lightbox.php.\n" );
	exit( 1 );
}

if ( 1 !== substr_count( $source, '\\UM\\PluginUpdater\\register(' ) ) {
	fwrite( STDERR, "Updater registration must occur exactly once.\n" );
	exit( 1 );
}

$registration = strpos( $source, '\\UM\\PluginUpdater\\register(' );
$init_hook    = strpos( $source, "add_action( 'init'" );

if ( false === $registration || false === $init_hook || $registration > $init_hook ) {
	fwrite( STDERR, "Updater registration must run before the init-only plugin bootstrap.\n" );
	exit( 1 );
}

if ( preg_match( '/if\s*\(\s*is_admin\s*\(\s*\)\s*\)[\s\S]*?PluginUpdater\\\\register/', $source ) ) {
	fwrite( STDERR, "Updater registration must not be restricted to admin requests.\n" );
	exit( 1 );
}

echo "Little Lightbox updater bootstrap test passed.\n";
