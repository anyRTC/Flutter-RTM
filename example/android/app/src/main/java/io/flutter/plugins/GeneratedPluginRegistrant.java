package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import org.ar.rtm_engine.ArRtmPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    ArRtmPlugin.registerWith(registry.registrarFor("org.ar.rtm_engine.ArRtmPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
