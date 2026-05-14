"""
Quick standalone test for Fish Audio voice cloning.

Run from services/agent/:
    python test_fish.py

It will:
  1. Synthesise one line in Vijay's cloned voice via Fish Audio
  2. Save the MP3 to test_fish_output.mp3 in the current dir
  3. Print useful diagnostics if anything goes wrong

If you hear Vijay's voice in test_fish_output.mp3 → Fish is healthy and
the chat stream issue is downstream (WebSocket frame mime / browser
playback). If this script errors → fix that first; chat won't work
until it does.
"""
import asyncio
import os
import sys
from pathlib import Path

# Load .env from project root with an absolute path
from dotenv import load_dotenv
_ENV_PATH = Path(__file__).resolve().parents[2] / ".env"
if _ENV_PATH.exists():
    load_dotenv(_ENV_PATH)
    print(f"[test] loaded env from {_ENV_PATH}")
else:
    print(f"[test] !! .env not found at {_ENV_PATH}")


def banner(msg: str) -> None:
    print(f"\n──── {msg} " + "─" * (60 - len(msg)))


banner("env diagnostics")
print(f"  TTS_ENGINE          = {os.getenv('TTS_ENGINE')!r}")
print(f"  FISH_AUDIO_URL      = {os.getenv('FISH_AUDIO_URL')!r}")
print(f"  FISH_AUDIO_VOICE_ID = {os.getenv('FISH_AUDIO_VOICE_ID')!r}")
api_key = os.getenv("FISH_AUDIO_API_KEY", "")
print(f"  FISH_AUDIO_API_KEY  = {'(set, ' + str(len(api_key)) + ' chars)' if api_key else '(MISSING)'}")

if not api_key:
    print("\n❌ FISH_AUDIO_API_KEY not set in .env — abort.")
    sys.exit(1)
if not os.getenv("FISH_AUDIO_VOICE_ID"):
    print("\n❌ FISH_AUDIO_VOICE_ID not set in .env — abort.")
    sys.exit(1)


async def main() -> int:
    banner("calling fish audio")
    try:
        from tts_fish import synthesize_cloned
    except Exception as e:
        print(f"❌ Cannot import tts_fish: {e}")
        return 2

    text = "Vanakkam. Naan Vijay. Tamil Nadu mukkiyamana subjects oru sila."
    print(f"  text = {text!r}")

    try:
        mp3_bytes = await synthesize_cloned(text)
    except Exception as e:
        print(f"❌ Fish API call failed: {e}")
        print("\nLikely causes:")
        print("  • Wrong API key  → check fish.audio dashboard")
        print("  • Wrong voice id → check it's the reference_id from your model page")
        print("  • Network blocks api.fish.audio → try `Test-NetConnection api.fish.audio -Port 443`")
        return 3

    out = Path(__file__).parent / "test_fish_output.mp3"
    out.write_bytes(mp3_bytes)

    banner("result")
    print(f"  size       = {len(mp3_bytes):,} bytes")
    print(f"  saved to   = {out}")
    print(f"  first 4 B  = {mp3_bytes[:4]!r}    (should start with b'ID3' or b'\\xff\\xfb' for MP3)")

    if len(mp3_bytes) < 1000:
        print("\n⚠️  Response is suspiciously small — probably a JSON error message disguised as MP3.")
        print(f"     Raw body: {mp3_bytes!r}")
        return 4

    starts_with_mp3 = mp3_bytes[:3] == b"ID3" or mp3_bytes[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2")
    if not starts_with_mp3:
        print("\n⚠️  Bytes don't look like an MP3 header — Fish may be returning a different format.")
        return 5

    print("\n✅ Fish TTS works. Open test_fish_output.mp3 to hear Vijay.")
    print("   PowerShell: start test_fish_output.mp3")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
