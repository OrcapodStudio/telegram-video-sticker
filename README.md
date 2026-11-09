# telegram-video-sticker

Two small scripts for making Telegram video stickers from your own clips with ffmpeg, on your own computer. Nothing is uploaded anywhere.

- `make-sticker.sh` turns a video into a sticker that meets Telegram's rules, lowering the bitrate until it fits under 256 KB.
- `check-sticker.sh` checks any `.webm` against those rules before you upload it, and warns if it still carries hidden details from the original video, such as where it was filmed.

## Telegram's rules for video stickers

| Rule | Limit |
| --- | --- |
| Format | `.webm`, VP9 video |
| Size on screen | one side exactly 512 px, the other 512 px or less |
| File size | 256 KB at most (262,144 bytes) |
| Length | 3 seconds at most |
| Frame rate | 30 FPS at most |
| Sound | none: no audio stream at all |

Source: [Telegram's sticker documentation](https://core.telegram.org/stickers).

## Use

You need [ffmpeg](https://ffmpeg.org/) built with libvpx (most packaged builds are).

```sh
./make-sticker.sh input.mp4            # first 3 seconds -> sticker.webm
./make-sticker.sh input.mp4 5 cat.webm # start 5 seconds in
./check-sticker.sh cat.webm            # exit code 0 when every check passes
```

Then open [@Stickers](https://t.me/stickers) in Telegram, start a new video sticker set, and send the file **as a file**, not as a video.

The single command at the heart of it:

```sh
ffmpeg -i input.mp4 -t 3 -an -map_metadata -1 \
  -vf "fps=30,scale=512:512:force_original_aspect_ratio=decrease" \
  -c:v libvpx-vp9 -b:v 400k -y sticker.webm
```

`-map_metadata -1` matters: without it, ffmpeg copies the source video's metadata (on phone videos, often the GPS location, phone model and capture time) into the sticker.

## Tested

With ffmpeg 6.1 on a 6-second 1080x1920, 60 FPS clip with sound and a GPS tag: 288x512 VP9, 3.00 s, about 120 KB, no audio, no location tag.

## On an iPhone instead

The full guide, including the reasons Telegram rejects a file, is at [weejistick.com/guides/telegram-video-stickers](https://weejistick.com/guides/telegram-video-stickers). Disclosure: that site is ours, and we also make [Weejistick](https://weejistick.com), an iPhone app that does the same conversion on the phone. These scripts are free and stand on their own.

## License

MIT. See `LICENSE`.
