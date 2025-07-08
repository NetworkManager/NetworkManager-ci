#!/usr/bin/env python3
"""Remove old test scenarios from feature files based on version tags."""
import os
import re
import argparse
from collections import defaultdict
from dataclasses import dataclass
from typing import List, Set

@dataclass
class Scenario:
    """A test scenario with version-based removal logic."""
    filepath: str
    start_idx: int
    lines: List[str]
    name: str
    tags: List[str]
    should_remove: bool = False
    
    @property
    def end_idx(self) -> int:
        return self.start_idx + len(self.lines) - 1
    
    @property
    def test_name(self) -> str:
        """Extract test name from tags, fallback to scenario name."""
        version_pattern = r'^@(ver|rhelver|fedoraver)(?:/[^/]+/[^/]+)?(?:[+\-]=|[+\-]\d+(\.\d+)*|\d+(\.\d+)*)$'
        for tag in reversed(self.tags):
            if not (tag.startswith('@rhbz') or re.match(version_pattern, tag)) and ' ' not in tag:
                return tag.lstrip('@')
        return self.name

def parse_version(v: str) -> tuple:
    """Parse version string to comparable tuple."""
    parts = list(map(int, v.split('.')))
    return tuple((parts + [0, 0, 0])[:3])

def extract_versions(tags: List[str], suffix: str) -> List[tuple]:
    """Extract versions with given suffix from tags."""
    pattern = rf'@(?:ver|rhelver|fedoraver)(?:/[^/]+/[^/]+)?{re.escape(suffix)}(\d+\.\d+(?:\.\d+)*)'
    versions = []
    for tag in tags:
        for match in re.findall(pattern, tag):
            try:
                versions.append(parse_version(match))
            except ValueError:
                pass
    return versions

def should_keep(scenario: Scenario, target: tuple) -> bool:
    """Determine if scenario should be kept based on version constraints."""
    plus_vers = extract_versions(scenario.tags, '+=')
    minus_eq_vers = extract_versions(scenario.tags, '-=')
    minus_vers = extract_versions(scenario.tags, '-')
    
    # Determine upper bound
    upper_bound, is_exclusive = None, False
    if minus_eq_vers and (not minus_vers or min(minus_eq_vers) < min(minus_vers)):
        upper_bound, is_exclusive = min(minus_eq_vers), False
    elif minus_vers:
        upper_bound, is_exclusive = min(minus_vers), True
    
    # Apply @ver+= override (makes it open-ended if override applies)
    if plus_vers and (not upper_bound or max(plus_vers) > upper_bound):
        return True
    
    # Check bounds
    if not upper_bound:
        return True
    return upper_bound > target if is_exclusive else upper_bound >= target

def parse_feature_file(filepath: str) -> List[Scenario]:
    """Parse feature file and extract scenarios."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    scenarios, current = [], {'lines': [], 'tags': [], 'name': '', 'start': -1, 'state': 0}
    
    def save():
        if current['name'] and current['lines']:
            scenarios.append(Scenario(filepath, current['start'], current['lines'][:], 
                                    current['name'], current['tags'][:]))
        current.update({'lines': [], 'tags': [], 'name': '', 'start': -1, 'state': 0})
    
    for i, line in enumerate(lines):
        s = line.strip()
        
        if s.startswith(('Feature:', 'Background:')):
            save()
        elif s.startswith('#') and current['state'] in [1, 2]:
            current['lines'].append(line)
        elif s.startswith('@'):
            if current['state'] in [0, 2]:
                save()
                current['start'], current['state'] = i, 1
            current['tags'].extend(s.split())
            current['lines'].append(line)
        elif s.startswith(('Scenario:', 'Scenario Outline:')):
            if current['state'] in [0, 2]:
                save()
                current['start'] = i
            current['state'], current['name'] = 2, s.split(':', 1)[1].strip()
            current['lines'].append(line)
        elif current['state'] in [1, 2]:
            current['lines'].append(line)
    
    save()
    return scenarios

def collect_scenarios(path: str, is_file: bool = False) -> List[Scenario]:
    """Collect all scenarios from path."""
    if is_file:
        return parse_feature_file(path)
    
    scenarios = []
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith('.feature'):
                scenarios.extend(parse_feature_file(os.path.join(root, file)))
    return scenarios

def rewrite_files(scenarios: List[Scenario]):
    """Rewrite feature files excluding removed scenarios."""
    by_file = defaultdict(list)
    for s in scenarios:
        by_file[s.filepath].append(s)
    
    for filepath, file_scenarios in by_file.items():
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.readlines()
        
        result, pos = [], 0
        for scenario in sorted(file_scenarios, key=lambda x: x.start_idx):
            result.extend(original[pos:scenario.start_idx])
            if not scenario.should_remove:
                result.extend(scenario.lines)
            pos = scenario.end_idx + 1
        result.extend(original[pos:])
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(result)

def update_mapper(mapper_path: str, kept: Set[str], removed: Set[str]):
    """Update mapper.yaml by removing entries for fully deleted tests."""
    try:
        with open(mapper_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        result, skip_test, test_indent = [], False, -1
        removed_count = 0
        
        for line in lines:
            if match := re.match(r'^\s*-\s*([a-zA-Z0-9_]+):\s*$', line):
                test_name = match.group(1)
                if test_name in removed and test_name not in kept:
                    skip_test, test_indent = True, len(line) - len(line.lstrip())
                    removed_count += 1
                    continue
                skip_test = False
            elif skip_test:
                current_indent = len(line) - len(line.lstrip())
                if current_indent < test_indent and line.strip():
                    skip_test = False
                else:
                    continue
            
            result.append(line)
        
        with open(mapper_path, 'w', encoding='utf-8') as f:
            f.writelines(result)
        
        print(f"Removed {removed_count} entries from mapper.yaml")
        
    except Exception as e:
        print(f"Error processing mapper: {e}")

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Remove old test scenarios from feature files")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--dir', '-d', help='Directory containing feature files')
    source.add_argument('--file', '-f', help='Single feature file path')
    parser.add_argument('--target-version', '-t', required=True, help='Target version (e.g. "1.40.0")')
    parser.add_argument('--mapper', '-m', required=True, help='Path to mapper.yaml file')
    parser.add_argument('--dry-run', '-n', action='store_true', help='Show what would be removed without making changes')
    args = parser.parse_args()
    
    # Validate and process
    path = args.dir or args.file
    if not os.path.exists(path):
        parser.error(f"Path '{path}' does not exist")
    
    target_version = parse_version(args.target_version)
    scenarios = collect_scenarios(path, bool(args.file))
    
    removed_names, kept_names = set(), set()
    scenario_details = defaultdict(lambda: {'removed': 0, 'kept': 0, 'reasons': []})
    
    for scenario in scenarios:
        keep = should_keep(scenario, target_version)
        scenario.should_remove = not keep
        name = scenario.test_name
        
        # Track details for reporting
        if keep:
            kept_names.add(name)
            scenario_details[name]['kept'] += 1
            # Find reason for keeping
            plus_vers = extract_versions(scenario.tags, '+=')
            if plus_vers:
                scenario_details[name]['reasons'].append(f"has @ver+= (open-ended from {max(plus_vers)})")
            elif not extract_versions(scenario.tags, '-=') and not extract_versions(scenario.tags, '-'):
                scenario_details[name]['reasons'].append("no version constraints (current)")
            else:
                scenario_details[name]['reasons'].append(f"upper bound >= target version")
        else:
            removed_names.add(name)
            scenario_details[name]['removed'] += 1
    
    # Report what will be done
    if removed_names:
        print(f"{'Would remove' if args.dry_run else 'Removing'} scenarios for {len(removed_names)} test types:")
        for name in sorted(removed_names):
            details = scenario_details[name]
            status = f"  {name}: {details['removed']} scenario(s) removed"
            if name in kept_names:
                reasons = list(set(details['reasons']))  # Remove duplicates
                reason_text = ", ".join(reasons) if reasons else "newer scenarios exist"
                status += f", {details['kept']} kept ({reason_text})"
            print(status)
        
        # Explain mapper impact
        mapper_removals = removed_names - kept_names
        if mapper_removals:
            print(f"\nWill remove {len(mapper_removals)} entries from mapper.yaml (tests with no remaining scenarios)")
        else:
            print(f"\nNo mapper.yaml entries will be removed (all removed tests have newer scenarios)")
    else:
        print("No scenarios to remove")
    
    # Execute changes unless dry run
    if not args.dry_run:
        rewrite_files(scenarios)
        update_mapper(args.mapper, kept_names, removed_names)
    else:
        print(f"\nDry run complete. Use without --dry-run to apply changes.")

if __name__ == "__main__":
    main()
