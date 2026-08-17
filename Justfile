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
    done < <(find . -type f -regextype posix-extended \
                -regex '.*\.(hcl|tfstate|backup)|.*\.?plan$' -print0)

    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        echo "Found ${#files_to_remove[@]} file(s) to delete:"
        printf '  %s\n' "${files_to_remove[@]}"
        rm -rf "${files_to_remove[@]}"
        echo "Deleting '.terraform' directory."
        rm -rf .terraform
        echo "Deletion complete."
    else
        echo "No matching files found; nothing to delete."
    fi

generate-tofu:
    #!/usr/bin/env bash
    sed 's/1.15.8/1.12.5/' <providers.tf | tee providers.tofu
    sed 's/Terraform/OpenTofu/' <locals.tf | tee locals.tofu
    sed 's/"ssh-.*"/"<your_ssh_public_key>"/' <variables.tf | tee variables.tf.example

gh-set-secreats:
    #!/usr/bin/env bash
    gh secret set VES_P12_PASSWORD --body "$VES_P12_PASSWORD"
    gh secret set VES_P12_CONTENT --body "$VES_P12_CONTENT"
    gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
    gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
    gh secret set AWS_SESSION_TOKEN --body "$AWS_SESSION_TOKEN"
    gh secret set TF_VAR_extra_cidrs --body "$TF_VAR_extra_cidrs"
    gh secret set TF_VAR_public_key --body "$TF_VAR_public_key"
    gh secret set BACKEND_BUCEKT_NAME --body "$BACKEND_BUCEKT_NAME"
    gh secret set BACKEND_BUCKET_KEY --body "$BACKEND_BUCKET_KEY"
    gh secret set BACKEND_BUCKET_REGION --body "$BACKEND_BUCKET_REGION"
    gh secret list