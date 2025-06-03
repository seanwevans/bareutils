import argparse
import re
from pathlib import Path

DEFAULT_INDENT = 4
DEFAULT_COMMENT_COL = 40


def format_line(line: str, indent: int, comment_col: int) -> str:
    raw = line.rstrip('\n')
    stripped = raw.lstrip()

    # Empty or whitespace-only line
    if stripped == '':
        return ''

    # Lines that start with comment keep as is
    if stripped.startswith(';'):
        return stripped

    # Keep labels and directives at column 0
    if re.match(r"^[^\s].*:", stripped):
        return stripped
    if stripped.startswith('section') or stripped.startswith('global'):
        return stripped

    # Split code and comment
    if ';' in raw:
        code_part, comment_part = raw.split(';', 1)
        comment = ';' + comment_part.strip()
    else:
        code_part, comment = raw, ''

    code = code_part.strip()
    # indent code
    formatted = ' ' * indent + code
    if comment:
        # Ensure at least one space before comment
        pad = comment_col - len(formatted)
        if pad < 1:
            pad = 1
        formatted += ' ' * pad + comment
    return formatted


def format_file(path: Path, indent: int, comment_col: int):
    lines = path.read_text().splitlines()
    formatted_lines = [format_line(line, indent, comment_col) for line in lines]
    path.write_text('\n'.join(formatted_lines) + '\n')


def main():
    parser = argparse.ArgumentParser(description="Format NASM assembly files")
    parser.add_argument('files', nargs='+', help='Assembly files to format')
    parser.add_argument('--indent', type=int, default=DEFAULT_INDENT,
                        help='Indentation width (default: %(default)s)')
    parser.add_argument('--comment-col', type=int, default=DEFAULT_COMMENT_COL,
                        help='Column to align comments (default: %(default)s)')
    args = parser.parse_args()

    for file in args.files:
        format_file(Path(file), args.indent, args.comment_col)


if __name__ == '__main__':
    main()
