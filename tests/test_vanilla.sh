#!/usr/bin/env bash
# Mock-Tests für minecraft_vanilla_server/run.sh
# Aufruf: tests/test_vanilla.sh (siehe tests/README.md)

# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="${REPO_DIR}/minecraft_vanilla_server/run.sh"

# Standard-Fixture: 26.3 (Java 25) ist latest, dazu ältere Versionen mit anderen Java-Anforderungen
vanilla_fixture() {
  mojang_reset
  mojang_add "26.3" 25
  mojang_add "1.21.1" 21
  mojang_add "1.20.4" 17
  mojang_add "1.12.2" none
  mojang_finish
}

t_eula_fehlt() {
  sandbox "EULA fehlt" "${SCRIPT}"
  vanilla_fixture
  set_options '{"accept_eula": false}'
  run_addon
  assert_rc 1
  assert_out_has "EULA"
  assert_calls "keine Downloads vor der Zustimmung" "." 0
  assert_no_file "server.jar"

  set_options '{"accept_eula": null}'
  run_addon
  assert_rc 1
  assert_out_has "accept_eula"
}

t_xms_groesser_xmx() {
  sandbox "Xms größer als Xmx" "${SCRIPT}"
  vanilla_fixture
  set_options '{"xms_mb": 4096, "xmx_mb": 1024}'
  run_addon
  assert_rc 1
  assert_out_has "darf nicht größer als xmx_mb"
  assert_calls "keine Downloads" "." 0
}

t_normalstart() {
  sandbox "Normalstart (latest, Java 25)" "${SCRIPT}"
  vanilla_fixture
  run_addon
  assert_rc 0
  assert_calls "Java 25 wird geladen (Issue 4: nicht mehr fest Java 21)" "adoptium.net/.*/latest/25/" 1
  assert_calls "Java 21 wird nicht geladen" "adoptium.net/.*/latest/21/" 0
  assert_file ".jre/25/bin/java"
  assert_out_has "Nutze neueste Minecraft-Version: 26.3"
  assert_out_has "Prüfsumme (SHA-1) ok"
  assert_file "server.jar"
  assert_file_has "server.jar" "SERVERJAR 26.3"
  assert_file_has "eula.txt" "eula=true"
  assert_file_has "server.properties" "server-port=25565"
  assert_java_args "major=25 args=-Xms512M -Xmx1024M -jar server.jar nogui"
  assert_out_has "Java Version: openjdk version \"25.0.1\""
  assert_no_file "server.jar.tmp"
}

t_java_aus_mojang_metadaten() {
  local ver java
  for pair in "1.21.1:21" "1.20.4:17" "1.12.2:8"; do
    ver="${pair%%:*}"
    java="${pair##*:}"
    sandbox "Java-Ermittlung ${ver} -> Java ${java}" "${SCRIPT}"
    vanilla_fixture
    set_options "{\"mc_version\": \"${ver}\"}"
    run_addon
    assert_rc 0
    assert_calls "Java ${java} wird geladen" "adoptium.net/.*/latest/${java}/" 1
    assert_java_args "major=${java} "
    assert_file_has "server.jar" "SERVERJAR ${ver}"
  done
}

t_java_major_option() {
  sandbox "java_major überschreibt die Mojang-Angabe" "${SCRIPT}"
  vanilla_fixture
  set_options '{"java_major": 21}'
  run_addon
  assert_rc 0
  assert_calls "Java 21 wird geladen" "adoptium.net/.*/latest/21/" 1
  assert_calls "Java 25 wird nicht geladen" "adoptium.net/.*/latest/25/" 0
}

t_java_pruefsumme_falsch() {
  sandbox "Falsche Java-Prüfsumme: Abbruch, keine Installation" "${SCRIPT}"
  vanilla_fixture
  jre_break_checksum 25
  run_addon
  assert_rc 1
  assert_out_has "Prüfsumme des Java-Archivs stimmt nicht überein"
  assert_no_file ".jre/25"
  assert_no_file ".jre/25.tmp"
  assert_no_file "server.jar"
  assert_java_args_none
}

t_adoptium_api_nicht_erreichbar() {
  sandbox "Adoptium-API nicht erreichbar bricht ab" "${SCRIPT}"
  vanilla_fixture
  echo "api.adoptium.net/*" > "${MOCK_FAIL}"
  run_addon
  assert_rc 1
  assert_out_has "Adoptium-API nicht erreichbar"
  assert_no_file "server.jar"
}

t_alte_java_wird_aufgeraeumt() {
  sandbox "Alte Java-Version wird entfernt (Update von 0.0.2)" "${SCRIPT}"
  vanilla_fixture
  mkdir -p "${DATA}/.jre/21/bin"
  printf '#!/bin/sh\nexit 0\n' > "${DATA}/.jre/21/bin/java"
  chmod +x "${DATA}/.jre/21/bin/java"
  run_addon
  assert_rc 0
  assert_file ".jre/25/bin/java"
  assert_no_file ".jre/21"
}

t_sigterm() {
  sandbox "SIGTERM führt zu stop und Exit 0" "${SCRIPT}"
  vanilla_fixture
  scenario_sigterm
}

t_neustart_ohne_redownload() {
  sandbox "Neustart ohne Re-Downloads" "${SCRIPT}"
  vanilla_fixture
  run_addon
  assert_rc 0
  assert_calls "erster Lauf lädt Java (API und Archiv)" "adoptium" 2
  assert_calls "erster Lauf lädt das Server-JAR" "piston-data" 1
  run_addon
  assert_rc 0
  assert_calls "zweiter Lauf: kein Java-Download" "adoptium" 0
  assert_calls "zweiter Lauf: kein JAR-Download" "piston-data" 0
  assert_calls "zweiter Lauf: nur die Metadaten" "piston-meta" 2
  assert_out_lacks "Lade Server-JAR herunter"
}

t_neue_version_laedt_neu() {
  sandbox "Neue Mojang-Version ersetzt das JAR" "${SCRIPT}"
  vanilla_fixture
  run_addon
  assert_file_has "server.jar" "SERVERJAR 26.3"
  mojang_reset
  mojang_add "26.4" 25
  mojang_add "26.3" 25
  mojang_finish
  run_addon
  assert_rc 0
  assert_file_has "server.jar" "SERVERJAR 26.4"
  assert_calls "JAR wird neu geladen" "piston-data" 1
  assert_calls "Java bleibt erhalten" "adoptium" 0
}

t_pruefsumme_falsch() {
  sandbox "Falsche Prüfsumme: Abbruch, keine JAR" "${SCRIPT}"
  mojang_reset
  mojang_add "26.3" 25 badsha
  mojang_finish
  run_addon
  assert_rc 1
  assert_out_has "Prüfsumme des Server-JAR stimmt nicht überein"
  assert_no_file "server.jar"
  assert_no_file "server.jar.tmp"
  assert_no_file ".server_jar_url.txt"
  assert_java_args_none
}

assert_java_args_none() {
  if [[ -s "${MOCK_JAVA_LOG}" ]]; then nok "java wurde unerwartet gestartet"; else ok "java wurde nicht gestartet"; fi
}

t_unbekannte_version() {
  sandbox "Unbekannte Version bricht ab" "${SCRIPT}"
  vanilla_fixture
  set_options '{"mc_version": "9.9.9"}'
  run_addon
  assert_rc 1
  assert_out_has "Unbekannte Minecraft-Version"
  assert_no_file "server.jar"
}

t_manifest_nicht_erreichbar() {
  sandbox "Mojang nicht erreichbar bricht ab" "${SCRIPT}"
  vanilla_fixture
  echo "piston-meta.mojang.com/*" > "${MOCK_FAIL}"
  run_addon
  assert_rc 1
  assert_out_has "Mojang-Versionsmanifest nicht erreichbar"
}

t_eigene_jar_url() {
  sandbox "Eigene server_jar_url (ohne Prüfsumme, Java aus mc_version)" "${SCRIPT}"
  vanilla_fixture
  mkdir -p "${MOCK_WWW}/files.example.com"
  printf 'CUSTOMJAR' > "${MOCK_WWW}/files.example.com/custom.jar"
  set_options '{"server_jar_url": "https://files.example.com/custom.jar", "mc_version": "1.21.1"}'
  run_addon
  assert_rc 0
  assert_out_has "benutzerdefinierte Server-JAR URL"
  assert_out_has "Download ist nicht verifiziert"
  assert_file_has "server.jar" "CUSTOMJAR"
  assert_calls "Java 21 passend zu mc_version" "adoptium.net/.*/latest/21/" 1
}

t_eigene_jar_url_nur_https() {
  sandbox "server_jar_url mit http wird abgelehnt" "${SCRIPT}"
  vanilla_fixture
  set_options '{"server_jar_url": "http://files.example.com/custom.jar"}'
  run_addon
  assert_rc 1
  assert_out_has "server_jar_url muss mit https:// beginnen"
  assert_calls "keine Downloads" "." 0
}

t_server_exitcode_wird_durchgereicht() {
  sandbox "Abstürzender Server: Exit-Code wird durchgereicht" "${SCRIPT}"
  vanilla_fixture
  export MOCK_JAVA_EXIT_CODE=3
  run_addon
  assert_rc 3
  assert_out_has "Server wurde beendet (Exit-Code 3)"
  export MOCK_JAVA_EXIT_CODE=0
}

for t in t_eula_fehlt t_xms_groesser_xmx t_normalstart t_java_aus_mojang_metadaten \
         t_java_major_option t_java_pruefsumme_falsch t_adoptium_api_nicht_erreichbar \
         t_alte_java_wird_aufgeraeumt t_sigterm \
         t_neustart_ohne_redownload t_neue_version_laedt_neu t_pruefsumme_falsch \
         t_unbekannte_version t_manifest_nicht_erreichbar t_eigene_jar_url \
         t_eigene_jar_url_nur_https t_server_exitcode_wird_durchgereicht; do
  "${t}"
done

summary
