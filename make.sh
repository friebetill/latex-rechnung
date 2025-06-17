#!/bin/bash

wait_for_enter() {
  read -r
}

create_new_customer() {
  echo "Enter customer company name:"
  read -re customerCompany
  echo "Enter customer name:"
  read -re customerName
  echo "Enter customer street:"
  read -re customerStreet
  echo "Enter customer ZIP code:"
  read -re customerZIP
  echo "Enter customer city:"
  read -re customerCity
  echo "Enter customer country (leave empty if not applicable):"
  read -re customerCountry
  echo "Enter customer VAT number (leave empty if not applicable):"
  read -re customerVAT

  echo "Apply reverse charge law? (yes/no):"
  read -re applyReverseChargeLaw
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
  read -re fileName

  customerFile="assets/customers/${fileName}.tex"
  echo "\\newcommand{\\customerLanguage}{${customerLanguage}}" >"${customerFile}"
  echo "" >>"${customerFile}"
  echo "\\newcommand{\\customerCompany}{${customerCompany}} %ggf. Firma" >>"${customerFile}"
  echo "\\newcommand{\\customerName}{${customerName}} % Name" >>"${customerFile}"
  echo "\\newcommand{\\customerStreet}{${customerStreet}} % Straße" >>"${customerFile}"
  echo "\\newcommand{\\customerZIP}{${customerZIP}} % Postleitzahl" >>"${customerFile}"
  echo "\\newcommand{\\customerCity}{${customerCity}} % Ort" >>"${customerFile}"
  echo "\\newcommand{\\customerCountry}{${customerCountry}}" >>"${customerFile}"
  echo "\\newcommand{\\customerVAT}{${customerVAT}} % VAT number" >>"${customerFile}"
  echo "\\newboolean{applyReverseChargeLaw}" >>"${customerFile}"
  echo "\\setboolean{applyReverseChargeLaw}{${applyReverseChargeLaw}}" >>"${customerFile}"

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
  default_pay_date=$(date -v+1m +%d.%m.%Y)
  default_invoice_reference=$(date +%Y%m%d)-1
  start_week=$(date -v-2w +%Y-W%V)
  end_week=$(date -v-1w +%Y-W%V)
  default_performance_period="${start_week} - ${end_week}"

  echo "Enter invoice date (format: DD.MM.YYYY) [Default: $default_invoice_date]:"
  read -re invoiceDate
  invoiceDate=${invoiceDate:-$default_invoice_date}

  echo "Enter payment due date (format: DD.MM.YYYY) [Default: $default_pay_date]:"
  read -re payDate
  payDate=${payDate:-$default_pay_date}

  echo "Enter invoice reference number [Default: $default_invoice_reference]:"
  read -re invoiceReference
  invoiceReference=${invoiceReference:-$default_invoice_reference}

  echo "Enter performance period (format: YYYY-WXX - YYYY-WXX) [Default: $default_performance_period]:"
  read -re performancePeriod
  performancePeriod=${performancePeriod:-$default_performance_period}

  echo "\\newcommand{\\invoiceDate}{${invoiceDate}} % Datum der rechnungsstellung" >"${invoice_data_file}"
  echo "\\newcommand{\\payDate}{${payDate}} % Datum der Zahlungsfrist (30 Tage nach Rechnungsstellung)" >>"${invoice_data_file}"
  echo "\\newcommand{\\invoiceReference}{${invoiceReference}} % Rechnungsnummer (z.B. 20150122-4)" >>"${invoice_data_file}"
  echo "\\newcommand{\\performancePeriod}{${performancePeriod}} % Leistungszeitraum (z.B. 2022-W46 - 2022-W47)" >>"${invoice_data_file}"

  echo "Invoice data file created at ${invoice_data_file}"
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

  echo "\\newcommand{\\fees}{" >"${fees_file}"

  while [[ $addMore == "y" ]]; do
    echo "Enter task description:"
    read -re taskDescription

    echo "Enter hourly rate:"
    read -re hourlyRate
    # Convert comma to period for LaTeX compatibility
    hourlyRate=${hourlyRate//,/.}

    echo "Enter total duration (in decimal hours):"
    read -re totalDuration
    # Convert comma to period for LaTeX compatibility
    totalDuration=${totalDuration//,/.}

    echo "  \\Fee{${taskDescription}}{${hourlyRate}}{${totalDuration}}" >>"${fees_file}"

    echo "Do you want to add another entry? (y/n):"
    read -re addMore
    addMore=${addMore:-n}
  done

  echo "}" >>"${fees_file}"

  echo "Fees data file created at ${fees_file}"
}

build_pdf() {
  echo "Press ENTER to build the pdf:"
  wait_for_enter

  lualatex assets/main.tex

  # Extract the invoice reference number from the LaTeX file using sed
  invoiceReference=$(sed -n 's/.*\\newcommand{\\invoiceReference}{\([^}]*\)}.*/\1/p' assets/invoice_data.tex)

  # Rename the output PDF to the invoice reference number
  if [ -n "$invoiceReference" ]; then
    mv main.pdf "${invoiceReference}.pdf"
  else
    echo "Error: Invoice reference number not found. PDF not renamed."
  fi

  rm assets/customer.tex
  rm assets/fees.tex
  rm assets/invoice_data.tex
  rm main.out
  rm main.log
  rm main.aux
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
