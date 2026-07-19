<?php

define( 'ABSPATH', __DIR__ );

$GLOBALS['llb_test_options'] = [];

function get_option( $key, $default = false ) {
	return array_key_exists( $key, $GLOBALS['llb_test_options'] ) ? $GLOBALS['llb_test_options'][ $key ] : $default;
}

function wp_parse_args( $args, $defaults = [] ) {
	return array_merge( $defaults, $args );
}

require_once dirname( __DIR__ ) . '/includes/class-settings.php';
require_once dirname( __DIR__ ) . '/includes/class-feature-telemetry.php';

function llb_assert_same( $expected, $actual, string $message ): void {
	if ( $expected !== $actual ) {
		fwrite( STDERR, $message . PHP_EOL );
		exit( 1 );
	}
}

$config = MZV_LB_Feature_Telemetry::config();
llb_assert_same( 1, $config['schema_version'], 'Schema version mismatch.' );
llb_assert_same( 8, count( $config['fields'] ), 'Schema field count mismatch.' );

$defaults = MZV_LB_Feature_Telemetry::collect( 'little-lightbox' );
llb_assert_same( 'enhanced', $defaults['lightbox_mode'], 'Default mode mismatch.' );
llb_assert_same( true, $defaults['gallery_enabled'], 'Default gallery state mismatch.' );

$GLOBALS['llb_test_options'][ MZV_LB_Settings::OPTION_KEY ] = [
	'lightbox_mode'              => 'css',
	'caption_source'             => 'title',
	'gallery_enabled'            => false,
	'animations_enabled'         => false,
	'recipe_card_lightbox'       => false,
	'wprm_jump_enabled'          => false,
	'allow_ads_above_lightbox'   => true,
	'trigger_icon_size'          => 'super',
];

$custom = MZV_LB_Feature_Telemetry::collect( 'little-lightbox' );
llb_assert_same( 'css', $custom['lightbox_mode'], 'Custom mode mismatch.' );
llb_assert_same( 'title', $custom['caption_source'], 'Custom caption source mismatch.' );
llb_assert_same( true, $custom['allow_ads_above_lightbox'], 'Custom ad setting mismatch.' );
llb_assert_same( 'super', $custom['trigger_icon_size'], 'Custom icon size mismatch.' );

$GLOBALS['llb_test_options'][ MZV_LB_Settings::OPTION_KEY ]['lightbox_mode'] = 'private-value';
$GLOBALS['llb_test_options'][ MZV_LB_Settings::OPTION_KEY ]['caption_source'] = 'caption text';
$GLOBALS['llb_test_options'][ MZV_LB_Settings::OPTION_KEY ]['trigger_icon_size'] = '../secret';

$invalid = MZV_LB_Feature_Telemetry::collect( 'little-lightbox' );
llb_assert_same( 'enhanced', $invalid['lightbox_mode'], 'Invalid mode was not normalized.' );
llb_assert_same( 'alt', $invalid['caption_source'], 'Invalid caption source was not normalized.' );
llb_assert_same( 'normal', $invalid['trigger_icon_size'], 'Invalid icon size was not normalized.' );

echo "Little Lightbox feature telemetry tests passed.\n";
