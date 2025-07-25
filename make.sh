#!/bin/zsh

wait_for_enter() {
  read -r
}

create_new_customer() {
  echo "Enter customer company name:"
  read -r customerCompany
  echo "Enter customer name:"
  read -r customerName
  echo "Enter customer street:"
  read -r customerStreet
  echo "Enter customer ZIP code:"
  read -r customerZIP
  echo "Enter customer city:"
  read -r customerCity
  echo "Enter customer country (leave empty if not applicable):"
  read -r customerCountry
  echo "Enter customer VAT number (leave empty if not applicable):"
  read -r customerVAT

  echo "Apply reverse charge law? (yes/no):"
  read -r applyReverseChargeLaw
  if [ "$applyReverseChargeLaw" == "yes" ]; then
    applyReverseChargeLaw=true
  else
    applyReverseChargeLaw=false
  fi


  echo "Select the language for the invoice by entering the corresponding number:"
  options=("English" "German" "French" "Spanish" "Italian" "Dutch" "Afrikaans" "Estonian" "Finnish" "Swedish")

  PS3="Enter the number corresponding to your choice: "

  select opt in "${options[@]}"; do
    case $REPLY in
      1) customerLanguage="english"; break ;;
      2) customerLanguage="ngerman"; break ;;
      3) customerLanguage="french"; break ;;
      4) customerLanguage="spanish"; break ;;
      5) customerLanguage="italian"; break ;;
      6) customerLanguage="dutch"; break ;;
      7) customerLanguage="afrikaans"; break ;;
      8) customerLanguage="estonian"; break ;;
      9) customerLanguage="finnish"; break ;;
      10) customerLanguage="swedish"; break ;;
      *) echo "Invalid selection. Please enter a number between 1 and ${#options[@]}." ;;
    esac
  done

  echo "Enter file name for the new customer (without extension):"
  read -r fileName

  customerFile="assets/customers/${fileName}.tex"
  printf '\\newcommand{\\customerLanguage}{%s}\n' "$customerLanguage" >"${customerFile}"
  printf '\\newcommand{\\customerCompany}{%s} %%ggf. Firma\n' "$customerCompany" >>"${customerFile}"
  printf '\\newcommand{\\customerName}{%s} %% Name\n' "$customerName" >>"${customerFile}"
  printf '\\newcommand{\\customerStreet}{%s} %% Straße\n' "$customerStreet" >>"${customerFile}"
  printf '\\newcommand{\\customerZIP}{%s} %% Postleitzahl\n' "$customerZIP" >>"${customerFile}"
  printf '\\newcommand{\\customerCity}{%s} %% Ort\n' "$customerCity" >>"${customerFile}"
  printf '\\newcommand{\\customerCountry}{%s}\n' "$customerCountry" >>"${customerFile}"
  printf '\\newcommand{\\customerVAT}{%s} %% VAT number\n' "$customerVAT" >>"${customerFile}"
  printf '\\newboolean{applyReverseChargeLaw}\n' >>"${customerFile}"
  printf '\\setboolean{applyReverseChargeLaw}{%s}\n' "$applyReverseChargeLaw" >>"${customerFile}"

  cp "${customerFile}" assets/customer.tex
}

select_existing_customer() {
  echo "Select an existing customer file:"
  select customerFile in assets/customers/*.tex; do
    if [ -n "$customerFile" ]; then
      cp "${customerFile}" assets/customer.tex
      break
    else
      echo "Invalid selection. Please try again."
    fi
  done
}

prompt_invoice_data() {
  local invoice_data_file="assets/invoice_data.tex"

  default_invoice_date=$(date +%d.%m.%Y)

  invoiceDate=$(read_with_prefill "Enter invoice date: " "$default_invoice_date")

  # Produce default reference like YYYYMMDD-1 derived from the invoice date
  default_invoice_reference=$(generate_invoice_reference "$invoiceDate")

  # Calculate default payment due date based on the chosen invoice date
  default_pay_date=$(calculate_default_pay_date "$invoiceDate")

  payDate=$(read_with_prefill "Enter payment due date: " "$default_pay_date")

  invoiceReference=$(read_with_prefill "Enter invoice reference number: " "$default_invoice_reference")

  # Calculate default performance period (last 4 weeks before invoice date)
  default_performance_period=$(calculate_performance_period "$invoiceDate")

  performancePeriod=$(read_with_prefill "Enter performance period: " "$default_performance_period")

  printf '\\newcommand{\\invoiceDate}{%s} %% Datum der rechnungsstellung\n' "$invoiceDate" >"${invoice_data_file}"
  printf '\\newcommand{\\payDate}{%s} %% Datum der Zahlungsfrist (14 Tage nach Rechnungsstellung)\n' "$payDate" >>"${invoice_data_file}"
  printf '\\newcommand{\\invoiceReference}{%s} %% Rechnungsnummer (z.B. 20150122-4)\n' "$invoiceReference" >>"${invoice_data_file}"
  printf '\\newcommand{\\performancePeriod}{%s} %% Leistungszeitraum (z.B. 2022-W46 - 2022-W47)\n' "$performancePeriod" >>"${invoice_data_file}"

  echo "Invoice data file created at ${invoice_data_file}"
}

calculate_default_pay_date() {
  local inputDate="$1"

  # Zero-pad day and month (e.g. 7.5.2025 → 07.05.2025)
  IFS='.' read -r d m y <<< "$inputDate"
  d=$(printf "%02d" "$d")
  m=$(printf "%02d" "$m")
  local padded="${d}.${m}.${y}"

  # Add 14 days via epoch arithmetic
  local seconds_in_14_days=$((14*24*60*60))
  local epoch
  epoch=$(date -j -f "%d.%m.%Y" "$padded" +%s 2>/dev/null) || epoch=""

  if [ -n "$epoch" ]; then
    local target=$((epoch + seconds_in_14_days))
    date -j -r "$target" +"%d.%m.%Y"
  else
    # Fallback to padded input if parsing failed
    echo "$padded"
  fi
}

generate_invoice_reference() {
  # Convert DD.MM.YYYY → YYYYMMDD-1.
  local inputDate="$1"
  IFS='.' read -r d m y <<< "$inputDate"
  d=$(printf "%02d" "$d")
  m=$(printf "%02d" "$m")
  echo "${y}${m}${d}-1"
}

calculate_performance_period() {
  local inv="$1"

  # Convert invoice date to epoch seconds
  local inv_epoch
  inv_epoch=$(date -j -f "%d.%m.%Y" "$inv" +%s 2>/dev/null) || inv_epoch=""

  if [ -z "$inv_epoch" ]; then
    echo ""  # return empty on parse failure
    return
  fi

  local seconds_per_week=$((7*24*60*60))
  local start_epoch=$((inv_epoch - 3*seconds_per_week))

  local end_week start_week
  end_week=$(date -j -r "$inv_epoch" +%Y-W%V)
  start_week=$(date -j -r "$start_epoch" +%Y-W%V)

  echo "${start_week} - ${end_week}"
}

move_timemator_data() {
  echo "Move TimeMator data to timemator_data.csv:"
  echo "Press enter when done"
  wait_for_enter
  python assets/timemator_reader.py >assets/fees.tex
}

prompt_fees_data() {
  local fees_file="assets/fees.tex"
  local taskDescription hourlyRate totalDuration addMore="y"

  printf '\\newcommand{\\fees}{\n' >"${fees_file}"

  while [[ $addMore == "y" ]]; do
    echo "Enter task description:"
    read -r taskDescription

    echo "Enter hourly rate:"
    read -r hourlyRate
    # Convert comma to period for LaTeX compatibility
    hourlyRate=${hourlyRate//,/.}

    echo "Enter total duration (in decimal hours):"
    read -r totalDuration
    # Convert comma to period for LaTeX compatibility
    totalDuration=${totalDuration//,/.}

    printf '  \\Fee{%s}{%s}{%s}\n' "$taskDescription" "$hourlyRate" "$totalDuration" >>"${fees_file}"

    echo "Do you want to add another entry? (y/n):"
    read -r addMore
    addMore=${addMore:-n}
  done

  printf '}\n' >>"${fees_file}"

  echo "Fees data file created at ${fees_file}"
}

build_pdf() {
  echo "Press ENTER to build the pdf:"
  wait_for_enter

  # Ensure lualatex is available
  if ! command -v lualatex >/dev/null 2>&1; then
    echo "Error: 'lualatex' command not found. Please install a TeX distribution (e.g., TeX Live or MacTeX) and ensure lualatex is in your PATH." >&2
    return
  fi

  lualatex assets/main.tex

  # Extract the invoice reference number from the LaTeX file using sed
  invoiceReference=$(sed -n 's/.*\\newcommand{\\invoiceReference}{\([^}]*\)}.*/\1/p' assets/invoice_data.tex)

  # Rename the output PDF to the invoice reference number
  if [ -n "$invoiceReference" ]; then
    mv main.pdf "${invoiceReference}.pdf"
  else
    echo "Error: Invoice reference number not found. PDF not renamed."
  fi

  rm -f assets/customer.tex assets/fees.tex assets/invoice_data.tex main.out main.log main.aux
}

read_with_prefill() {
  # Usage: var=$(read_with_prefill "Prompt" "defaultValue")
  local prompt="$1"
  local default_val="$2"

  # If running under zsh, use 'vared' for inline editable default.
  if [[ -n "$ZSH_VERSION" ]]; then
    local __input="$default_val"
    # vared prints the prompt itself; send directly to user terminal.
    vared -p "$prompt" __input < /dev/tty >&2
    echo "${__input:-$default_val}"
    return
  fi

  # Bash 4+ supports -i with read for inline default.
  if [[ -n "$BASH_VERSION" ]]; then
    local major=${BASH_VERSINFO[0]}
    if (( major >= 4 )); then
      # shellcheck disable=SC2162
      read -e -i "$default_val" -p "$prompt" REPLY < /dev/tty 1>&2
      echo "${REPLY:-$default_val}"
      return
    fi
  fi

  # Generic fallback: show default in brackets and accept empty input.
  printf "%s[Default: %s] " "$prompt" "$default_val" >&2
  read -r REPLY < /dev/tty
  echo "${REPLY:-$default_val}"
}

main() {
  echo "Do you want to (1) create a new customer or (2) select an existing customer?"
  select choice in "Create New Customer" "Select Existing Customer"; do
    case $REPLY in
    1)
      create_new_customer
      break
      ;;
    2)
      select_existing_customer
      break
      ;;
    *)
      echo "Invalid option. Please select 1 or 2."
      ;;
    esac
  done

  prompt_invoice_data

  echo "Do you want to (1) move TimeMator data or (2) enter fees data directly?"
  select choice in "Move TimeMator Data" "Enter Fees Data"; do
    case $REPLY in
    1)
      move_timemator_data
      break
      ;;
    2)
      prompt_fees_data
      break
      ;;
    *)
      echo "Invalid option. Please select 1 or 2."
      ;;
    esac
  done

  build_pdf

  echo "Done."
}

main
