#!/bin/bash
# Configure UFW (Uncomplicated Firewall) with safe defaults

set -e

status "Firewall Configuration"

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    status "UFW is not installed, installing it..."
    install_package "ufw" repo
fi

# Check current UFW status
ufw_status=$(sudo ufw status | head -n 1)

status "Current firewall status: $ufw_status"

# Show configuration options
option=$(gum choose "Enable/Disable Firewall" "Configure Default Rules" "Allow/Block Services" "Show Current Rules" "Back")

case "$option" in
    "Enable/Disable Firewall")
        if [[ "$ufw_status" == *"inactive"* ]]; then
            if gum confirm "Enable the firewall?"; then
                sudo ufw --force enable
                status "Firewall enabled successfully"
            fi
        else
            if gum confirm "Disable the firewall? This is not recommended."; then
                sudo ufw --force disable
                status "Firewall disabled"
            fi
        fi
        ;;

    "Configure Default Rules")
        incoming=$(gum choose "deny" "allow" "reject" --header "Default policy for incoming connections:")
        outgoing=$(gum choose "deny" "allow" "reject" --header "Default policy for outgoing connections:")

        sudo ufw default "$incoming" incoming
        sudo ufw default "$outgoing" outgoing

        status "Default policies updated: incoming=$incoming, outgoing=$outgoing"
        ;;

    "Allow/Block Services")
        action=$(gum choose "Allow" "Block" "Delete Rule")

        case "$action" in
            "Allow")
                allowtype=$(gum choose "Common Service" "Custom Port")

                if [[ "$allowtype" == "Common Service" ]]; then
                    services=("SSH (22)" "HTTP (80)" "HTTPS (443)" "FTP (21)" "MySQL/MariaDB (3306)" "PostgreSQL (5432)")
                    selected=$(gum choose "${services[@]}")

                    case "$selected" in
                        "SSH (22)")
                            sudo ufw allow ssh
                            ;;
                        "HTTP (80)")
                            sudo ufw allow http
                            ;;
                        "HTTPS (443)")
                            sudo ufw allow https
                            ;;
                        "FTP (21)")
                            sudo ufw allow ftp
                            ;;
                        "MySQL/MariaDB (3306)")
                            sudo ufw allow 3306/tcp
                            ;;
                        "PostgreSQL (5432)")
                            sudo ufw allow 5432/tcp
                            ;;
                    esac

                    status "$selected has been allowed"
                else
                    port=$(gum input --placeholder "Enter port number")
                    if [[ "$port" =~ ^[0-9]+$ ]]; then
                        protocol=$(gum choose "tcp" "udp" "both")
                        if [[ "$protocol" == "both" ]]; then
                            sudo ufw allow "$port"
                        else
                            sudo ufw allow "$port"/"$protocol"
                        fi
                        status "Port $port ($protocol) has been allowed"
                    else
                        status "Invalid port number. Aborting."
                    fi
                fi
                ;;

            "Block")
                blocktype=$(gum choose "Common Service" "Custom Port")

                if [[ "$blocktype" == "Common Service" ]]; then
                    services=("SSH (22)" "HTTP (80)" "HTTPS (443)" "FTP (21)" "MySQL/MariaDB (3306)" "PostgreSQL (5432)")
                    selected=$(gum choose "${services[@]}")

                    case "$selected" in
                        "SSH (22)")
                            sudo ufw deny ssh
                            ;;
                        "HTTP (80)")
                            sudo ufw deny http
                            ;;
                        "HTTPS (443)")
                            sudo ufw deny https
                            ;;
                        "FTP (21)")
                            sudo ufw deny ftp
                            ;;
                        "MySQL/MariaDB (3306)")
                            sudo ufw deny 3306/tcp
                            ;;
                        "PostgreSQL (5432)")
                            sudo ufw deny 5432/tcp
                            ;;
                    esac

                    status "$selected has been blocked"
                else
                    port=$(gum input --placeholder "Enter port number")
                    if [[ "$port" =~ ^[0-9]+$ ]]; then
                        protocol=$(gum choose "tcp" "udp" "both")
                        if [[ "$protocol" == "both" ]]; then
                            sudo ufw deny "$port"
                        else
                            sudo ufw deny "$port"/"$protocol"
                        fi
                        status "Port $port ($protocol) has been blocked"
                    else
                        status "Invalid port number. Aborting."
                    fi
                fi
                ;;

            "Delete Rule")
                # Show numbered rules
                status "Current firewall rules:"
                sudo ufw status numbered | tail -n +5

                rule_number=$(gum input --placeholder "Enter rule number to delete (or 'c' to cancel)")

                if [[ "$rule_number" == "c" ]]; then
                    status "Deletion cancelled"
                elif [[ "$rule_number" =~ ^[0-9]+$ ]]; then
                    if gum confirm "Delete rule number $rule_number?"; then
                        sudo ufw --force delete "$rule_number"
                        status "Rule $rule_number deleted"
                    else
                        status "Deletion cancelled"
                    fi
                else
                    status "Invalid rule number. Aborting."
                fi
                ;;
        esac
        ;;

    "Show Current Rules")
        status "Current firewall rules:"
        sudo ufw status verbose
        echo ""
        gum input --placeholder "Press Enter to continue"
        ;;

    "Back")
        return 0
        ;;
esac
