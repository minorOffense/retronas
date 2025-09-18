

import re
import yaml

input_file = "/home/mwinstone/Development/github/retronas/ansible/retronas_systems.yml"
output_file = "/home/mwinstone/Development/github/retronas/ansible/retronas_systems.yml.updated"
batocera_file = "/home/mwinstone/Development/github/retronas/batocera.yml"

# Parse batocera.yml into a dict: {batocera_key: romm_value}
with open(batocera_file, "r") as bf:
    batocera_data = yaml.safe_load(bf)
batocera_map = batocera_data.get("system", {}).get("platforms", {})



def extract_field(line, field):
    # Extract field: "..." from the line
    m = re.search(rf'{field}:\s*"([^"]+)"', line)
    if m:
        return m.group(1)
    return None


def fuzzy_match_field(field_value, platforms):
    # Use difflib to find the closest match
    if not field_value:
        return None
    # Try exact match (case-insensitive) for system_name
    for sys_name, folder_name in platforms.items():
        if field_value.strip().lower() == sys_name.strip().lower():
            return folder_name
    # Try exact match (case-insensitive) for folder_name
    for sys_name, folder_name in platforms.items():
        if field_value.strip().lower() == folder_name.strip().lower():
            return folder_name
    # Fuzzy match (prefer folder_name if close)
    sys_matches = difflib.get_close_matches(field_value, platforms.keys(), n=1, cutoff=0.7)
    folder_matches = difflib.get_close_matches(field_value, platforms.values(), n=1, cutoff=0.7)
    if folder_matches:
        return folder_matches[0]
    if sys_matches:
        return platforms[sys_matches[0]]
    # Substring match
    for sys_name, folder_name in platforms.items():
        if field_value.lower() in sys_name.lower() or sys_name.lower() in field_value.lower():
            return folder_name
        if field_value.lower() in folder_name.lower() or folder_name.lower() in field_value.lower():
            return folder_name
    return None


def add_romm_to_line(line):
    if line.strip().startswith("- {") and "romm:" not in line:
        batocera_value = extract_field(line, "batocera")
        romm_value = ""
        if batocera_value and batocera_value in batocera_map:
            romm_value = batocera_map[batocera_value]
        line = line.rstrip().rstrip("}")
        parts = line.split(",")
        if len(parts) > 1:
            parts.insert(-1, f' romm: "{romm_value}"')
        else:
            parts.append(f' romm: "{romm_value}"')
        new_line = ",".join(parts) + " }"
        return new_line
    return line




with open(input_file, "r") as f_in, open(output_file, "w") as f_out:
    for line in f_in:
        new_line = add_romm_to_line(line.rstrip("\n")) if line.endswith("\n") else add_romm_to_line(line)
        f_out.write(new_line + ("\n" if line.endswith("\n") else ""))

print(f"Updated file written to {output_file}")
