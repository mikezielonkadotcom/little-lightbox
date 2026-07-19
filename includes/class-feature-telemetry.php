<?php
/**
 * Bounded feature telemetry for Little Lightbox update checks.
 *
 * @package MZV_Lightbox
 */

defined( 'ABSPATH' ) || exit;

class MZV_LB_Feature_Telemetry {

	/**
	 * Return the reviewed SDK schema and callback.
	 */
	public static function config(): array {
		return [
			'schema_version' => 1,
			'fields'         => [
				'allow_ads_above_lightbox' => [ 'type' => 'boolean' ],
				'animations_enabled'       => [ 'type' => 'boolean' ],
				'caption_source'            => [ 'type' => 'enum', 'values' => [ 'alt', 'description', 'none', 'title' ] ],
				'gallery_enabled'           => [ 'type' => 'boolean' ],
				'lightbox_mode'              => [ 'type' => 'enum', 'values' => [ 'css', 'enhanced' ] ],
				'recipe_card_lightbox'       => [ 'type' => 'boolean' ],
				'trigger_icon_size'          => [ 'type' => 'enum', 'values' => [ 'jumbo', 'normal', 'super' ] ],
				'wprm_jump_enabled'          => [ 'type' => 'boolean' ],
			],
			'callback'       => [ self::class, 'collect' ],
		];
	}

	/**
	 * Collect a feature-state snapshot without content or identifiers.
	 */
	public static function collect( string $slug = '' ): array {
		unset( $slug );
		$options = MZV_LB_Settings::get_options();

		return [
			'allow_ads_above_lightbox' => ! empty( $options['allow_ads_above_lightbox'] ),
			'animations_enabled'       => ! empty( $options['animations_enabled'] ),
			'caption_source'            => self::enum_value( $options['caption_source'] ?? '', [ 'alt', 'description', 'none', 'title' ], 'alt' ),
			'gallery_enabled'           => ! empty( $options['gallery_enabled'] ),
			'lightbox_mode'              => self::enum_value( $options['lightbox_mode'] ?? '', [ 'css', 'enhanced' ], 'enhanced' ),
			'recipe_card_lightbox'       => ! empty( $options['recipe_card_lightbox'] ),
			'trigger_icon_size'          => self::enum_value( $options['trigger_icon_size'] ?? '', [ 'jumbo', 'normal', 'super' ], 'normal' ),
			'wprm_jump_enabled'          => ! empty( $options['wprm_jump_enabled'] ),
		];
	}

	/**
	 * Constrain stored values to a reviewed enum.
	 *
	 * @param mixed $value Stored option value.
	 */
	private static function enum_value( $value, array $allowed, string $fallback ): string {
		return is_string( $value ) && in_array( $value, $allowed, true ) ? $value : $fallback;
	}
}
