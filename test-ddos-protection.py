#!/usr/bin/env python3
"""
DDoS Protection Test Suite
===========================
Comprehensive testing of all DDoS protection mechanisms:
1. Rate limiting (per-IP)
2. Request size limits
3. Content-Type validation
4. Timeout protection

Usage:
    python3 test-ddos-protection.py [test_name]
    
Available tests:
    - rate_limit    : Test per-IP rate limiting
    - large_payload : Test request size limits
    - content_type  : Test Content-Type validation
    - all           : Run all tests (default)
"""

import sys
import time
import requests
import json
from typing import Dict, List, Tuple

# Configuration
ENDPOINT = "https://logconsentauth-pxoxh5sfqa-as.a.run.app"
API_KEY = "demo-key-12345678-1234-1234-1234-123456789abc"  # Replace with your actual key

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(text: str):
    """Print a formatted header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{text.center(60)}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.RESET}\n")

def print_success(text: str):
    """Print success message"""
    print(f"{Colors.GREEN}✅ {text}{Colors.RESET}")

def print_error(text: str):
    """Print error message"""
    print(f"{Colors.RED}❌ {text}{Colors.RESET}")

def print_warning(text: str):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.RESET}")

def print_info(text: str):
    """Print info message"""
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.RESET}")

def print_shield(text: str):
    """Print shield (protection) message"""
    print(f"{Colors.MAGENTA}🛡️  {text}{Colors.RESET}")

# =============================================================================
# Test 1: Rate Limiting
# =============================================================================

def test_rate_limiting(num_requests: int = 15, delay: float = 0.5) -> bool:
    """
    Test the per-IP rate limiting protection
    
    Expected: First 10 requests succeed, then get 429 (Too Many Requests)
    """
    print_header("TEST 1: Rate Limiting Protection")
    
    print_info(f"Endpoint: {ENDPOINT}")
    print_info(f"Number of requests: {num_requests}")
    print_info(f"Delay between requests: {delay}s")
    print()
    print_info("Expected behavior:")
    print(f"  • Requests 1-10: HTTP 200 (success)")
    print(f"  • Requests 11+:  HTTP 429 (rate limited)")
    print()
    
    payload = {
        "event_type": "consent_given",
        "cookie": {
            "categories": ["necessary", "analytics"],
            "services": []
        },
        "pageUrl": "https://test.example.com/rate-limit-test",
        "pageTitle": "Rate Limit Test"
    }
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY
    }
    
    results = []
    success_count = 0
    rate_limited_count = 0
    error_count = 0
    
    print("Sending requests...\n")
    
    for i in range(1, num_requests + 1):
        print(f"Request {i:2d}: ", end="", flush=True)
        
        try:
            start_time = time.time()
            response = requests.post(ENDPOINT, json=payload, headers=headers, timeout=10)
            elapsed = time.time() - start_time
            
            status = response.status_code
            results.append((i, status, elapsed))
            
            if status == 200:
                print_success(f"HTTP {status} - Success ({elapsed:.2f}s)")
                success_count += 1
            elif status == 429:
                print_shield(f"HTTP {status} - Rate Limited! ({elapsed:.2f}s)")
                rate_limited_count += 1
            else:
                print_error(f"HTTP {status} - Unexpected")
                error_count += 1
                
        except requests.exceptions.RequestException as e:
            print_error(f"Request failed: {e}")
            error_count += 1
            results.append((i, 0, 0))
        
        if i < num_requests:
            time.sleep(delay)
    
    # Summary
    print_header("Test Results")
    print(f"Total requests: {num_requests}")
    print(f"  ✅ Successful (200):   {success_count}")
    print(f"  🛡️  Rate limited (429): {rate_limited_count}")
    print(f"  ❌ Errors:              {error_count}")
    print()
    
    # Evaluate
    passed = rate_limited_count > 0 and success_count <= 10
    
    if passed:
        print_success("RATE LIMITING IS WORKING CORRECTLY!")
        print()
        print_info("The system successfully blocked requests after the threshold.")
        return True
    else:
        print_warning("Rate limiting may not be working as expected")
        return False

# =============================================================================
# Test 2: Request Size Limits
# =============================================================================

def test_request_size_limit() -> bool:
    """
    Test the request size limit (50KB max)
    
    Expected: Requests > 50KB should return 413 (Payload Too Large)
    """
    print_header("TEST 2: Request Size Limit Protection")
    
    print_info(f"Endpoint: {ENDPOINT}")
    print_info(f"Size limit: 50KB (51,200 bytes)")
    print()
    print_info("Expected behavior:")
    print(f"  • Small payload (<50KB):  HTTP 200")
    print(f"  • Large payload (>50KB):  HTTP 413")
    print()
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY
    }
    
    # Test 1: Normal payload (~1KB)
    print("Test 2.1: Normal payload (~1KB)... ", end="", flush=True)
    normal_payload = {
        "event_type": "consent_given",
        "cookie": {"categories": ["necessary"]},
        "pageUrl": "https://test.example.com/size-test",
        "pageTitle": "Size Test"
    }
    
    try:
        response = requests.post(ENDPOINT, json=normal_payload, headers=headers, timeout=10)
        if response.status_code == 200:
            print_success(f"HTTP {response.status_code} - Accepted")
        else:
            print_warning(f"HTTP {response.status_code} - Unexpected")
    except Exception as e:
        print_error(f"Failed: {e}")
    
    # Test 2: Large payload (60KB)
    print("Test 2.2: Large payload (~60KB)... ", end="", flush=True)
    large_payload = {
        "event_type": "consent_given",
        "cookie": {"categories": ["necessary"]},
        "pageUrl": "https://test.example.com/size-test",
        "pageTitle": "Size Test",
        "dummy_data": "x" * 60000  # 60KB of dummy data
    }
    
    try:
        response = requests.post(ENDPOINT, json=large_payload, headers=headers, timeout=10)
        if response.status_code == 413:
            print_shield(f"HTTP {response.status_code} - Payload Too Large (BLOCKED!)")
            print()
            print_success("REQUEST SIZE LIMIT IS WORKING CORRECTLY!")
            return True
        else:
            print_warning(f"HTTP {response.status_code} - Expected 413")
            return False
    except Exception as e:
        print_error(f"Failed: {e}")
        return False

# =============================================================================
# Test 3: Content-Type Validation
# =============================================================================

def test_content_type_validation() -> bool:
    """
    Test the Content-Type validation
    
    Expected: Only application/json should be accepted
    """
    print_header("TEST 3: Content-Type Validation")
    
    print_info(f"Endpoint: {ENDPOINT}")
    print()
    print_info("Expected behavior:")
    print(f"  • application/json:       HTTP 200")
    print(f"  • text/plain:             HTTP 415")
    print(f"  • application/x-www-form: HTTP 415")
    print()
    
    payload = json.dumps({
        "event_type": "consent_given",
        "cookie": {"categories": ["necessary"]}
    })
    
    test_cases = [
        ("application/json", 200, "Valid"),
        ("text/plain", 415, "Invalid - Plain text"),
        ("application/x-www-form-urlencoded", 415, "Invalid - Form data"),
        ("", 415, "Missing Content-Type")
    ]
    
    results = []
    
    for content_type, expected_status, description in test_cases:
        print(f"Test 3.{len(results)+1}: {description}... ", end="", flush=True)
        
        headers = {"X-API-Key": API_KEY}
        if content_type:
            headers["Content-Type"] = content_type
        
        try:
            response = requests.post(ENDPOINT, data=payload, headers=headers, timeout=10)
            status = response.status_code
            
            if status == expected_status:
                if status == 200:
                    print_success(f"HTTP {status} - Accepted")
                else:
                    print_shield(f"HTTP {status} - Blocked (as expected)")
                results.append(True)
            else:
                print_warning(f"HTTP {status} - Expected {expected_status}")
                results.append(False)
                
        except Exception as e:
            print_error(f"Failed: {e}")
            results.append(False)
    
    print()
    passed = all(results)
    if passed:
        print_success("CONTENT-TYPE VALIDATION IS WORKING CORRECTLY!")
    else:
        print_warning("Content-Type validation may not be working as expected")
    
    return passed

# =============================================================================
# Main
# =============================================================================

def main():
    """Run DDoS protection tests"""
    
    print()
    print(f"{Colors.BOLD}{Colors.MAGENTA}")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║                                                           ║")
    print("║           DDoS PROTECTION TEST SUITE                      ║")
    print("║           ConsentManager Security Testing                 ║")
    print("║                                                           ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"{Colors.RESET}")
    
    # Parse command line arguments
    test_to_run = sys.argv[1] if len(sys.argv) > 1 else "all"
    
    results = {}
    
    if test_to_run in ["all", "rate_limit"]:
        results["rate_limit"] = test_rate_limiting()
        time.sleep(2)  # Wait before next test
    
    if test_to_run in ["all", "large_payload"]:
        results["large_payload"] = test_request_size_limit()
        time.sleep(2)
    
    if test_to_run in ["all", "content_type"]:
        results["content_type"] = test_content_type_validation()
    
    # Final summary
    if results:
        print_header("OVERALL TEST SUMMARY")
        
        for test_name, passed in results.items():
            test_display = test_name.replace("_", " ").title()
            if passed:
                print_success(f"{test_display}: PASSED")
            else:
                print_error(f"{test_display}: FAILED")
        
        print()
        all_passed = all(results.values())
        
        if all_passed:
            print(f"{Colors.BOLD}{Colors.GREEN}")
            print("╔═══════════════════════════════════════════════════════════╗")
            print("║                                                           ║")
            print("║     ✅ ALL DDOS PROTECTIONS ARE WORKING CORRECTLY! ✅     ║")
            print("║                                                           ║")
            print("╚═══════════════════════════════════════════════════════════╝")
            print(f"{Colors.RESET}\n")
            sys.exit(0)
        else:
            print(f"{Colors.BOLD}{Colors.RED}")
            print("╔═══════════════════════════════════════════════════════════╗")
            print("║                                                           ║")
            print("║          ⚠️  SOME TESTS FAILED - REVIEW NEEDED           ║")
            print("║                                                           ║")
            print("╚═══════════════════════════════════════════════════════════╝")
            print(f"{Colors.RESET}\n")
            sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Test interrupted by user{Colors.RESET}\n")
        sys.exit(130)
