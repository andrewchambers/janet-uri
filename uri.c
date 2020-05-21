#include <janet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if !defined(JANET_BSD) && !defined(JANET_WINDOWS)
#include <alloca.h>
#endif
#ifdef JANET_WINDOWS
#include "malloc.h"
#define alloca _alloca
#endif

static int decode_nibble(uint8_t b) {
  if (b >= '0' && b <= '9')
    return b - '0';
  if (b >= 'a' && b <= 'f')
    return 10 + b - 'a';
  if (b >= 'A' && b <= 'F')
    return 10 + b - 'A';
  return 0;
}

static int unreserved(uint8_t c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
         (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~';
}

static char *chartab = "0123456789abcdef";

static Janet jescape(int argc, Janet *argv) {
  janet_fixarity(argc, 1);
  const uint8_t *str = janet_getstring(argv, 0);
  size_t len = janet_string_length(str);
  size_t nwritten = 0;

  uint8_t *tmp = NULL;
#define NALLOCA 128
  if (len >= NALLOCA)
    tmp = janet_smalloc(len * 3);
  else
    tmp = alloca(len * 3);

  for (size_t i = 0; i < len; i++) {
    uint8_t c = str[i];
    if (unreserved(c)) {
      tmp[nwritten++] = c;
    } else {
      tmp[nwritten++] = '%';
      tmp[nwritten++] = chartab[(c & 0xf0) >> 4];
      tmp[nwritten++] = chartab[c & 0x0f];
    }
  }

  Janet escaped = janet_stringv(tmp, nwritten);

  if (len >= NALLOCA)
    janet_sfree(tmp);
  return escaped;
#undef NALLOCA
}

static Janet _junescape(const uint8_t *str, size_t len) {
  size_t nwritten = 0;
  uint8_t *tmp = NULL;
#define NALLOCA 128
  if (len >= NALLOCA)
    tmp = janet_smalloc(len);
  else
    tmp = alloca(len);

  int st = 0;
  uint8_t nb1, nb2;
  for (size_t i = 0; i < len; i++) {
    uint8_t c = str[i];
    switch (st) {
    case 0:
      switch (c) {
      case '%':
        st = 1;
        break;
      default:
        tmp[nwritten++] = c;
        break;
      }
      break;
    case 1:
      st = 2;
      nb1 = decode_nibble(c);
      break;
    case 2:
      st = 0;
      nb2 = decode_nibble(c);
      tmp[nwritten++] = (nb1 << 4) | nb2;
      break;
    default:
      abort();
    }
  }

  Janet unescaped = janet_stringv(tmp, nwritten);

  if (len >= NALLOCA)
    janet_sfree(tmp);

  return unescaped;
#undef NALLOCA
}

static Janet junescape(int argc, Janet *argv) {
  janet_fixarity(argc, 1);
  const uint8_t *str = janet_getstring(argv, 0);
  size_t len = janet_string_length(str);
  return _junescape(str, len);
}

static const JanetReg cfuns[] = {
    {"escape", jescape, "(uri/escape s)\n\nuri escape s"},
    {"unescape", junescape, "(uri/unescape s)\n\nuri unescape s"},
    {NULL, NULL, NULL}};

JANET_MODULE_ENTRY(JanetTable *env) { janet_cfuns(env, "uri", cfuns); }
