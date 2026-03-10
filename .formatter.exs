[
  inputs: [
    "lib/**/*.{ex,exs}",
    "test/**/*.{ex,exs}",
    "mix.exs"
  ],
  locals_without_parens: [
    command: 1,
    command: 2,
    middleware: 1,
    answer: 2,
    answer: 3,
    answer: 4,
    edit: 5,
    keyboard: 2,
    keyboard: 3,
    row: 1,
    button: 1,
    button: 2,
    reply_button: 1,
    reply_button: 2,
    inline_button: 1,
    inline_button: 2
  ],
  plugins: [
    Styler
  ],
  line_length: 120,
  exports: [
    locals_without_parens: [
      keyboard: 2,
      keyboard: 3,
      button: 1,
      button: 2,
      reply_button: 1,
      reply_button: 2,
      inline_button: 1,
      inline_button: 2
    ]
  ]
]
