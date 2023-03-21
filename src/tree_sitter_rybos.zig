const c = @cImport({
    @cInclude("tree_sitter/parser.h");
});

pub const Language = c.TSLanguage;

extern "c" fn tree_sitter_rybos() Language;

pub fn create() Language {
    return tree_sitter_rybos();
}
