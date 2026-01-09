# FUNCTIONS

sso-root(){
   sso "ROOT"
}

sso-production(){
   sso "production"
}

sso-sandbox(){
   sso "sandbox"
}

sso-datascience(){
   sso "datascience"
}

sso(){
    local profile=$1
    
    # Clear existing AWS environment variables
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SECURITY_TOKEN
    
    # Set and export the new profile
    export AWS_PROFILE=$profile
    
    # Check if token is valid
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "Token expired or not found for profile $profile, logging in..."
        aws sso login
    else
        echo "Using cached credentials for profile $profile"
    fi
}

sts-sandbox(){
    unset-credentials
    sso-root
    sts "arn:aws:iam::590183736435:role/organization-admin" "laguna-sandbox-cluster"
}

sts-highmark(){
    unset-credentials
    sso-root
    sts "arn:aws:iam::992382399644:role/organization-admin" "laguna-highmark-cluster"
}

sts-production(){
    unset-credentials
    sso-root
    sts "arn:aws:iam::992382399644:role/organization-admin" "laguna-production-cluster"
}

sts-dev(){
    unset-credentials
    sso-root
    sts "arn:aws:iam::590183736435:role/organization-admin" "laguna-develop-cluster"
}

sts-us(){
    unset-credentials
    sso-root
    sts "arn:aws:iam::066158985398:role/organization-admin" "laguna-us-cluster"
}

k9s-sandbox(){
    sts-sandbox
    k9s
}

k9s-highmark(){
    sts-highmark
    k9s
}

k9s-production(){
    sts-production
    k9s
}

k9s-dev(){
    sts-dev
    k9s
}

k9s-us(){
    sts-us
    k9s
}

sts() {
    role_arn=$1
    cluster_name=$2
  
    credentials=$(aws sts assume-role --role-arn $role_arn --role-session-name session)
    export AWS_ACCESS_KEY_ID=$(jq -r -n --argjson data "$credentials" '$data.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(jq -r -n --argjson data "$credentials" '$data.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(jq -n --argjson data "$credentials" '$data.Credentials.SessionToken')

    aws eks update-kubeconfig --region us-east-1 --name $cluster_name 
}

dremio-highmark() {
    open -a "Google Chrome" "https://dremio.highmark.lagunahealth.com"
}

dremio-develop() {
    open -a "Google Chrome" "https://dremio.develop.lagunahealth.com"
}

dremio-prod() {
    open -a "Google Chrome" "https://dremio.prod.lagunahealth.com"
}

superset-highmark(){
    open -a "Google Chrome" "https://superset.highmark.lagunahealth.com"
}

superset-develop(){
    open -a "Google Chrome" "https://superset.develop.lagunahealth.com"
}

superset-prod(){
    open -a "Google Chrome" "https://superset.prod.lagunahealth.com"
}

groundcover-web(){
    open -a "Google Chrome" "https://app.groundcover.com"
}

laguna-vpn(){
    open -a "Google Chrome" "https://lagunahealth.openvpn.com"
}

laguna-vpn-get-password(){
    op read op://Employee/OpenVPN/password
}

google-otp(){
    op read "op://Employee/Google/one-time password?attribute=otp"
}

unset-credentials(){
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}


# ADD JVM TO PATH
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# ADD ISTIO TO PATH
export PATH="$HOME/Documents/work/Workdir/istio/istio-1.23.2/bin:$PATH"

# K8S CERT ALIASES
namespace=hmkus
alias get-public-cert="kubectl get secret ${namespace}-drachtio-cert -n $namespace -o jsonpath='{.data.tls\.crt}' | base64 -d"
alias get-public-cert-full="kubectl get secret ${namespace}-drachtio-cert -n $namespace -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout"
alias get-private-cert="kubectl get secret ${namespace}-drachtio-cert -n $namespace -o jsonpath='{.data.tls\.key}' | base64 -d"
alias get-private-cert-full="kubectl get secret ${namespace}-drachtio-cert -n $namespace -o jsonpath='{.data.tls\.key}' | base64 -d | openssl rsa -text -noout"
alias get-fingerprint="kubectl get secret ${namespace}-drachtio-cert -n $namespace -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -fingerprint -sha256 -noout"

# KUBECTL aliases

alias k="kubectl"
alias ka="kubectl get all -o wide"
alias ks="kubectl get services -o wide"
alias kn="kubectl get namespaces -o wide"
alias kap="kubectl apply -f "

# ISTIO aliases
alias i="istioctl"

# TERRAFORM
alias tf="terraform"

# Smart Terragrunt aliases that auto-detect environment and set AWS_PROFILE
# Unset the old alias first
unalias tg 2>/dev/null
tg() {
    local current_dir=$(pwd)
    local aws_profile=""
    
    # Detect environment from current directory path
    if [[ "$current_dir" == *"/envs/develop/"* ]] || [[ "$current_dir" == *"/envs/qa/"* ]] || [[ "$current_dir" == *"/envs/sandbox/"* ]] || [[ "$current_dir" == *"/envs/preview"* ]]; then
        aws_profile="development"
    elif [[ "$current_dir" == *"/envs/production/"* ]] || [[ "$current_dir" == *"/envs/highmark/"* ]]; then
        aws_profile="production"
    elif [[ "$current_dir" == *"/envs/us/"* ]]; then
        aws_profile="us"
    elif [[ "$current_dir" == *"/envs/ops/"* ]] || [[ "$current_dir" == *"/envs/gsuite/"* ]]; then
        aws_profile="ops"
    elif [[ "$current_dir" == *"/envs/shared/"* ]]; then
        aws_profile="shared-resources"
    else
        # Fallback to current AWS_PROFILE if no environment detected
        aws_profile="${AWS_PROFILE:-development}"
        echo "⚠️  Could not detect environment from path. Using AWS_PROFILE=${aws_profile}"
    fi
    
    echo "🚀 Running terragrunt with AWS_PROFILE=${aws_profile}"
    AWS_PROFILE="$aws_profile" terragrunt "$@"
}

# Terragrunt aliases for specific commands with smart environment detection
alias tgp='tg plan'
alias tga='tg apply'
alias tgd='tg destroy'
alias tgi='tg init'
alias tgv='tg validate'
alias tgf='tg fmt'
alias tgs='tg show'
alias tgo='tg output'

# Legacy alias for manual override
alias terragrunt-manual="terragrunt"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export PATH=/Users/alonbecker/.groundcover/bin:${PATH}

export TERRAGRUNT_FORWARD_TF_STDOUT=true
export AWS_PROFILE=development

# Laguna Infrastructure SSO Functions
# Replacement for sso-root with environment-specific authentication

sso-development() {
    export AWS_PROFILE=development
    echo "🔐 Logging into Development account..."
    aws sso login --profile development
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged into Development account"
        echo "📋 Current identity:"
        aws sts get-caller-identity
        echo ""
        echo "💡 You can now run Terragrunt in:"
        echo "   - develop environments"
        echo "   - qa environments" 
        echo "   - preview1-5 environments"
        echo ""
        echo "🎯 Which EKS cluster would you like to configure kubectl for?"
        echo "1) laguna-develop-cluster"
        echo "2) laguna-sandbox-cluster"
        echo "3) Skip kubectl configuration"
        echo ""
        echo -n "Enter your choice (1-3): "
        read cluster_choice
        
        case $cluster_choice in
            1)
                echo "🔧 Configuring kubectl for laguna-develop-cluster..."
                AWS_PROFILE=development aws eks update-kubeconfig --region us-east-1 --name laguna-develop-cluster --profile development
                echo "✅ kubectl configured for develop cluster"
                ;;
            2)
                echo "🔧 Configuring kubectl for laguna-sandbox-cluster..."
                AWS_PROFILE=sandbox aws eks update-kubeconfig --region us-east-1 --name laguna-sandbox-cluster --profile development
                echo "✅ kubectl configured for sandbox cluster"
                ;;
            3)
                echo "⏭️  Skipping kubectl configuration"
                ;;
            *)
                echo "❌ Invalid choice. Skipping kubectl configuration"
                ;;
        esac
    else
        echo "❌ Failed to log into Development account"
    fi
}

sso-production() {
    export AWS_PROFILE=production
    echo "🔐 Logging into Production account..."
    aws sso login --profile production
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged into Production account"
        echo "📋 Current identity:"
        aws sts get-caller-identity
        echo ""
        echo "💡 You can now run Terragrunt in:"
        echo "   - production environments"
        echo "   - highmark environments"
        echo ""
        echo "⚠️  Remember: Production changes require LAGUNA_PRODUCTION_CONFIRMED=true"
        echo ""
        echo "🎯 Which EKS cluster would you like to configure kubectl for?"
        echo "1) laguna-production-cluster"
        echo "2) laguna-highmark-cluster"
        echo "3) Skip kubectl configuration"
        echo ""
        echo -n "Enter your choice (1-3): "
        read cluster_choice
        
        case $cluster_choice in
            1)
                echo "🔧 Configuring kubectl for laguna-production-cluster..."
                AWS_PROFILE=production aws eks update-kubeconfig --region us-east-1 --name laguna-production-cluster --profile production
                echo "✅ kubectl configured for production cluster"
                ;;
            2)
                echo "🔧 Configuring kubectl for laguna-highmark-cluster..."
                aws eks update-kubeconfig --region us-east-1 --name laguna-highmark-cluster --profile production
                echo "✅ kubectl configured for highmark cluster"
                ;;
            3)
                echo "⏭️  Skipping kubectl configuration"
                ;;
            *)
                echo "❌ Invalid choice. Skipping kubectl configuration"
                ;;
        esac
    else
        echo "❌ Failed to log into Production account"
    fi
}

sso-ops() {
    export AWS_PROFILE=ops
    echo "🔐 Logging into Ops account..."
    aws sso login --profile ops
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged into Ops account"
        echo "📋 Current identity:"
        aws sts get-caller-identity
        echo ""
        echo "💡 You can now run Terragrunt in:"
        echo "   - ops environments"
        echo "   - gsuite environments"
    else
        echo "❌ Failed to log into Ops account"
    fi
}

sso-shared() {
    export AWS_PROFILE=shared-resources
    echo "🔐 Logging into Shared Resources account..."
    aws sso login --profile shared-resources
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged into Shared Resources account"
        echo "📋 Current identity:"
        aws sts get-caller-identity
        echo ""
        echo "💡 You can now run Terragrunt in:"
        echo "   - shared environments"
    else
        echo "❌ Failed to log into Shared Resources account"
    fi
}

sso-us() {
    export AWS_PROFILE=us
    echo "🔐 Logging into US account..."
    aws sso login --profile us
    if [ $? -eq 0 ]; then
        echo "✅ Successfully logged into US account"
        echo "📋 Current identity:"
        aws sts get-caller-identity
        echo ""
        echo "💡 You can now run Terragrunt in:"
        echo "   - us environments"
        echo ""
        echo "⚠️  Remember: Production-level changes require LAGUNA_PRODUCTION_CONFIRMED=true"
        echo ""
        echo "🎯 Which EKS cluster would you like to configure kubectl for?"
        echo "1) laguna-us-cluster"
        echo "2) Skip kubectl configuration"
        echo ""
        echo -n "Enter your choice (1-2): "
        read cluster_choice
        
        case $cluster_choice in
            1)
                echo "🔧 Configuring kubectl for laguna-us-cluster..."
                aws eks update-kubeconfig --region us-east-1 --name laguna-us-cluster --profile us
                echo "✅ kubectl configured for us cluster"
                ;;
            2)
                echo "⏭️  Skipping kubectl configuration"
                ;;
            *)
                echo "❌ Invalid choice. Skipping kubectl configuration"
                ;;
        esac
    else
        echo "❌ Failed to log into US account"
    fi
}

# Helper function to show all available SSO functions
sso-help() {
    echo "🔐 Available SSO login functions:"
    echo ""
    echo "  sso-development  - Login to Development account (develop, qa, preview1-5)"
    echo "  sso-production   - Login to Production account (production, highmark)"
    echo "  sso-us           - Login to US account (us)"
    echo "  sso-ops          - Login to Ops account (ops, gsuite)"
    echo "  sso-shared       - Login to Shared Resources account (shared)"
    echo ""
    echo "💡 Usage: Just run the function name, e.g.: sso-development"
    echo "📋 Current AWS Profile: \${AWS_PROFILE:-not set}"
}

use-hmkus() {
  export namespace="hmkus"
}

use-us() {
  export namespace="us"
}

use-us() {
  export namespace="production"
}

use-develop() {
  export namespace="develop"
}

use-qa() {
  export namespace="qa"
}


export PATH=$PATH:/opt/homebrew/bin
export PATH=$PATH:$(go env GOPATH)/bin
