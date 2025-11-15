#!/usr/bin/env python3
"""
Convert Octicons SVG files to Frappe icons.svg format
Only processes 24px icons (with and without fill variants)

Usage:
	python generate_octicons.py <input_directory> <output_file>

Example:
	python generate_octicons.py /path/to/octicons/icons ./frappe/public/icons/octicons/icons.svg
"""

import os
import sys
import re
import xml.etree.ElementTree as ET
from pathlib import Path


def extract_svg_content(svg_file_path):
	"""Extract content from Octicons SVG file"""
	try:
		# Read raw file to preserve formatting
		with open(svg_file_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Parse to extract viewBox
		tree = ET.parse(svg_file_path)
		root = tree.getroot()
		viewbox = root.get('viewBox', '0 0 24 24')
		
		# Extract inner content (everything between <svg> and </svg>)
		# Handle both single-line and multi-line SVGs
		svg_match = re.search(r'<svg[^>]*>(.*?)</svg>', content, re.DOTALL)
		if svg_match:
			inner_content = svg_match.group(1).strip()
		else:
			# Fallback: extract child elements
			inner_content = ''
			for child in root:
				inner_content += ET.tostring(child, encoding='unicode').strip()
		
		return viewbox, inner_content
	except Exception as e:
		print(f"Error parsing {svg_file_path}: {e}")
		return None, None


def is_24px_icon(filename):
	"""Check if file is a 24px icon"""
	return filename.endswith('-24.svg')


def extract_icon_name(filename):
	"""Extract icon name from filename, handling fill variants"""
	name = filename.replace('.svg', '')
	
	# Remove size suffix (e.g., -24)
	name = re.sub(r'-\d+$', '', name)
	
	return name


def generate_symbol_id(icon_name, is_fill=False):
	"""Generate Frappe-compatible symbol ID for 24px icons"""
	if is_fill:
		return f"icon-octicon-{icon_name}-fill-24"
	return f"icon-octicon-{icon_name}-24"


def convert_directory_to_icons(input_dir, output_file):
	"""Convert all 24px SVG files (including fill variants) to Frappe icons.svg format"""
	if not os.path.isdir(input_dir):
		print(f"Error: Directory '{input_dir}' does not exist.")
		return False
	
	# Find all 24px SVG files
	all_files = os.listdir(input_dir)
	svg_files = sorted([f for f in all_files if is_24px_icon(f)])
	
	if not svg_files:
		print(f"No 24px SVG files found in '{input_dir}'.")
		print("Looking for files ending with '-24.svg'")
		return False
	
	print(f"Found {len(svg_files)} 24px SVG files")
	
	# Start building the output SVG
	output_lines = [
		'<!--',
		'Octicons 24px icons converted for Frappe Framework',
		'Source: https://github.com/primer/octicons',
		'License: MIT',
		'-->',
		'<svg id="frappe-symbols" aria-hidden="true" style="display: none;" class="icon" xmlns="http://www.w3.org/2000/svg">',
	]
	
	processed_count = 0
	
	for svg_file in svg_files:
		file_path = os.path.join(input_dir, svg_file)
		viewbox, content = extract_svg_content(file_path)
		
		if viewbox and content:
			icon_name = extract_icon_name(svg_file)
			is_fill = '-fill' in svg_file
			symbol_id = generate_symbol_id(icon_name, is_fill)
			
			# Create symbol element
			symbol_open = f'\t<symbol viewBox="{viewbox}" xmlns="http://www.w3.org/2000/svg" id="{symbol_id}">'
			output_lines.append(symbol_open)
			
			# Add content (indented and formatted)
			content_lines = content.strip().split('\n')
			if len(content_lines) == 1:
				# Single line content
				output_lines.append(f'\t\t{content.strip()}')
			else:
				# Multi-line content - indent each line
				for line in content_lines:
					if line.strip():  # Skip empty lines
						output_lines.append(f'\t\t{line.strip()}')
			
			output_lines.append('\t</symbol>')
			output_lines.append('')  # Empty line between symbols
			processed_count += 1
			print(f"  Processed: {svg_file} -> {symbol_id}")
	
	# Close SVG tag
	output_lines.append('</svg>')
	
	# Create output directory if it doesn't exist
	output_path = Path(output_file)
	output_path.parent.mkdir(parents=True, exist_ok=True)
	
	# Write output file
	with open(output_file, 'w', encoding='utf-8') as f:
		f.write('\n'.join(output_lines))
	
	print(f"\nSuccessfully converted {processed_count} 24px icons to '{output_file}'")
	return True


def main():
	if len(sys.argv) < 3:
		print(__doc__)
		sys.exit(1)
	
	input_directory = sys.argv[1]
	output_file = sys.argv[2]
	
	success = convert_directory_to_icons(input_directory, output_file)
	sys.exit(0 if success else 1)


if __name__ == '__main__':
	main()

