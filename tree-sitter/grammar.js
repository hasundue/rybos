module.exports = grammar({
  name: 'rybos',

  rules: {
    source_file: $ => repeat($._expression),

    _expression: $ => choice(
      $.identifier,
      $.number,
    ),

    identifier: $ => /[a-zA-Z]+/,

    number: $ => /\d+/,
  },
});
