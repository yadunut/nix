# helper function to crop cs3223 slides
crop_slides() {
  input="$1"
  if [ -z "$input" ]; then
    echo "Usage: crop_slides <inputfile>"
    return 1
  fi

  # Get base name (without extension)
  base="${input%.*}"
  output="${base}-slides.mp4"

  # Crop left 2/3 of a 1280x640 video (≈853 px wide)
  nix run "nixpkgs#ffmpeg" -- -i "$input" -filter:v "crop=853:640:0:0" -c:a copy "$output"
}

mp3() {
  nix shell "nixpkgs#yt-dlp" "nixpkgs#ffmpeg" --command yt-dlp -x --audio-format mp3 $@
}
