#
set shell := ["bash", "-c"]

default:
  @just --list

check:
    terraform fmt
    - diff variables.tf{,.example}
    echo
    - diff locals.{tf,tofu}
    echo
    - diff providers.{tf,tofu}
    echo
    - diff backend.tf{,.example}
    echo
clean:
    #!/usr/bin/env bash
    echo "Running clean task with Bash..."

    files_to_remove=()
    while IFS= read -r -d '' f; do
        files_to_remove+=("$f")
    done < <(find . -type f -regex '.*\(\.\(hcl\|tfstate\|backup\)\|\.?plan\)$' -print0)

    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        echo "Found ${#files_to_remove[@]} file(s) to delete:"
        printf '  %s\n' "${files_to_remove[@]}"
        rm -f "${files_to_remove[@]}"
        echo "Deletion complete."
    else
        echo "No matching files found; nothing to delete."
    fi
    echo "Deleting '.terraform'."
    rm -rf .terraform

generate-tofu:
    #!/usr/bin/env bash
    sed 's/1.15.8/1.12.5/' <providers.tf | tee providers.tofu
    sed 's/Terraform/OpenTofu/' <locals.tf | tee locals.tofu