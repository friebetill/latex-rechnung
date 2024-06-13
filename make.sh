#!/bin/bash

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

  echo "Enter file name for the new customer (without extension):"
  read -r fileName

  customerFile="assets/customers/${fileName}.tex"
  echo "\\newcommand{\\customerCompany}{${customerCompany}} %ggf. Firma" >"${customerFile}"
  echo "\\newcommand{\\customerName}{${customerName}} % Name" >>"${customerFile}"
  echo "\\newcommand{\\customerStreet}{${customerStreet}} % Straße" >>"${customerFile}"
  echo "\\newcommand{\\customerZIP}{${customerZIP}} % Postleitzahl" >>"${customerFile}"
  echo "\\newcommand{\\customerCity}{${customerCity}} % Ort" >>"${customerFile}"

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
  read -r invoiceDate
  invoiceDate=${invoiceDate:-$default_invoice_date}

  echo "Enter payment due date (format: DD.MM.YYYY) [Default: $default_pay_date]:"
  read -r payDate
  payDate=${payDate:-$default_pay_date}

  echo "Enter invoice reference number [Default: $default_invoice_reference]:"
  read -r invoiceReference
  invoiceReference=${invoiceReference:-$default_invoice_reference}

  echo "Enter performance period (format: YYYY-WXX - YYYY-WXX) [Default: $default_performance_period]:"
  read -r performancePeriod
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

  echo "Enter task description:"
  read -r taskDescription

  echo "Enter hourly rate:"
  read -r hourlyRate

  echo "Enter total duration (in decimal hours):"
  read -r totalDuration

  echo "\\newcommand{\\fees}{" >"${fees_file}"
  echo "  \\Fee{${taskDescription}}{${hourlyRate}}{${totalDuration}}" >>"${fees_file}"
  echo "}" >>"${fees_file}"

  echo "Fees data file created at ${fees_file}"
}

build_pdf() {
  echo "Press ENTER to build the pdf:"
  wait_for_enter
  lualatex assets/main.tex
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
