#!/usr/bin/env python3
"""
Hospital Readmission Risk Report Generator
Reads CMS data from Azure Blob Storage, analyzes it, and generates a report using Claude API
"""

import os
import sys
import json
from datetime import datetime
from azure.storage.blob import BlobClient
from anthropic import Anthropic

# ============================================================================
# CONFIGURATION - REPLACE THESE WITH YOUR VALUES
# ============================================================================

AZURE_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=readmissiondata2026;AccountKey="
BLOB_CONTAINER_NAME = "cms-readmission-data"  # Replace with your actual container name
BLOB_FILE_NAME = "Hospital Readmissions Reduction prog hosp.csv"  # Replace with your actual CSV filename
CLAUDE_API_KEY = ""

# ============================================================================
# STEP 1: READ CSV FROM AZURE BLOB STORAGE
# ============================================================================

def read_csv_from_azure(connection_string, container_name, blob_name):
    """Download and read CSV file from Azure Blob Storage"""
    print(f"📥 Reading {blob_name} from Azure Blob Storage...")
    
    try:
        blob_client = BlobClient.from_connection_string(
            conn_str=connection_string,
            container_name=container_name,
            blob_name=blob_name
        )
        
        # Download blob content
        blob_data = blob_client.download_blob()
        csv_content = blob_data.readall().decode('utf-8')
        
        print(f"✅ Successfully read {blob_name}")
        return csv_content
    
    except Exception as e:
        print(f"❌ Error reading from Azure: {e}")
        sys.exit(1)

# ============================================================================
# STEP 2: ANALYZE CSV DATA AND CREATE SUMMARY
# ============================================================================

def analyze_hospital_data(csv_content):
    """Parse CSV and create a summary for Claude to analyze"""
    lines = csv_content.strip().split('\n')
    
    if len(lines) < 2:
        print("❌ CSV file appears to be empty or invalid")
        sys.exit(1)
    
    # Parse header
    headers = lines[0].split(',')
    
    # Simple analysis - collect basic stats
    total_hospitals = len(lines) - 1
    
    # Try to find key columns (adjust based on your actual CSV structure)
    readmission_col = None
    state_col = None
    measure_col = None
    
    for i, header in enumerate(headers):
        if 'excess' in header.lower() or 'readmission' in header.lower():
            readmission_col = i
        if 'state' in header.lower():
            state_col = i
        if 'measure' in header.lower():
            measure_col = i
    
    # Collect sample data for Claude
    sample_rows = []
    high_risk_count = 0
    
    for line in lines[1:min(101, len(lines))]:  # Sample first 100 rows
        values = line.split(',')
        sample_rows.append(values)
        
        # Count high-risk hospitals (ratio > 1.0)
        if readmission_col and readmission_col < len(values):
            try:
                ratio = float(values[readmission_col])
                if ratio > 1.0:
                    high_risk_count += 1
            except (ValueError, IndexError):
                pass
    
    summary = f"""
CMS Hospital Readmission Data Summary:
- Total hospitals in dataset: {total_hospitals}
- High-risk hospitals (ratio > 1.0): {high_risk_count}
- Sample data (first 100 rows):
{json.dumps(sample_rows[:5], indent=2)}

CSV Headers: {', '.join(headers)}
"""
    
    return summary

# ============================================================================
# STEP 3: GENERATE REPORT USING CLAUDE API
# ============================================================================

def generate_report_with_claude(api_key, data_summary):
    """Use Claude API to generate a plain-English risk report"""
    print("\n🤖 Generating report with Claude API...")
    
    client = Anthropic()
    
    prompt = f"""You are a healthcare data analyst. Based on the CMS hospital readmission data below, 
generate a professional, plain-English risk report that:

1. Summarizes the overall readmission risk landscape
2. Identifies the highest-risk hospitals or regions
3. Explains what the excess readmission ratio means in simple terms
4. Recommends 3-5 actionable steps hospitals should take to reduce readmissions
5. Highlights any data quality issues or missing information

Keep the report to 2-3 paragraphs, written for hospital administrators (not data scientists).

Data Summary:
{data_summary}

Report:"""
    
    try:
        message = client.messages.create(
            model="claude-opus-4-1",
            max_tokens=1024,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        
        report_text = message.content[0].text
        print("✅ Report generated successfully")
        return report_text
    
    except Exception as e:
        print(f"❌ Error calling Claude API: {e}")
        sys.exit(1)

# ============================================================================
# STEP 4: SAVE REPORT TO FILE
# ============================================================================

def save_report(report_text, output_format="txt"):
    """Save the generated report to a file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if output_format == "txt":
        filename = f"readmission_report_{timestamp}.txt"
    else:
        filename = f"readmission_report_{timestamp}.md"
    
    with open(filename, 'w') as f:
        f.write(f"Hospital Readmission Risk Report\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 60 + "\n\n")
        f.write(report_text)
    
    print(f"📄 Report saved to: {filename}")
    return filename

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    print("=" * 60)
    print("Hospital Readmission Risk Report Generator")
    print("=" * 60)
    
    # Check for API keys
    if CLAUDE_API_KEY == "YOUR_CLAUDE_API_KEY_HERE":
        print("❌ ERROR: Please set your CLAUDE_API_KEY in the script")
        print("   Get it from: https://console.anthropic.com/")
        sys.exit(1)
    
    if AZURE_CONNECTION_STRING == "YOUR_AZURE_CONNECTION_STRING_HERE":
        print("❌ ERROR: Please set your AZURE_CONNECTION_STRING in the script")
        print("   Get it from Azure Portal > Storage Account > Access Keys")
        sys.exit(1)
    
    # Set API key for Anthropic client
    os.environ['ANTHROPIC_API_KEY'] = CLAUDE_API_KEY
    
    # Step 1: Read data from Azure
    csv_data = read_csv_from_azure(
        AZURE_CONNECTION_STRING,
        BLOB_CONTAINER_NAME,
        BLOB_FILE_NAME
    )
    
    # Step 2: Analyze data
    data_summary = analyze_hospital_data(csv_data)
    
    # Step 3: Generate report with Claude
    report = generate_report_with_claude(CLAUDE_API_KEY, data_summary)
    
    # Step 4: Save report
    output_file = save_report(report)
    
    print("\n" + "=" * 60)
    print("✅ Pipeline Complete!")
    print("=" * 60)
    print(f"\nGenerated Report Preview:\n")
    print(report)

if __name__ == "__main__":
    main()
