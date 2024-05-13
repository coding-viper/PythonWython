  <#
  .Synopsis
     Gets the credential from the Windows Credential Manager ( WCM ).
  .DESCRIPTION
     The script gets the password for the given user id from the Windows Credential Manager ( WCM ). The script accepts two optional parameter Target and Type. 
     If the user id exists for the given user id, type (if provided) and target (if provided), a secure object type [System.Management.Automation.PSCredential] is returned otherwise an object of Type [System.COllections.Generic.IDictionary] is returned with the error Status and error Message.

  .EXAMPLE
     Get-WCMCredential -UserName 'stevejoseph@sampledomain.com'
  .EXAMPLE
     Get-WCMCrdential -UserName 'stevejoseph@sampledomain.com' -Target www.sampledomain.com
  .EXAMPLE
     Get-WCMCrdential -UserName 'stevejoseph@sampledomain.com' -Type GENERIC
  .EXAMPLE
     Get-WCMCrdential -UserName 'stevejoseph@sampledomain.com' -Target www.sampledomain.com -Type DOMAIN_CERTIFICATE
  .EXAMPLE
     Get-WCMCrdential -UserName 'stevejoseph@sampledomain.com' -Target www.sampledomain.com -Type GENERIC
  .EXAMPLE
     Get-WCMCrdential -UserName 'stevejoseph@sampledomain.com' -Target www.sampledomain.com -Type DOMAIN_PASSWORD
  .EXAMPLE
     Get-WCMCrdential 'stevejoseph@sampledomain.com' www.sampledomain.com GENERIC
  .EXAMPLE
     Get-WCMCrdential 'stevejoseph@sampledomain.com' www.sampledomain.com
  #>
 
     [CmdletBinding()]
     [Alias('gwc')]
     [OutputType([Object])]
     Param
     (
         # Specifies the name for which password needs to be retrieved.
         # The UserName is accepted exactly the way it has to be. There is no regular expression involved to search a given user. 
         #If the name contains any wildcards then it should be enclosed within single quotation mark. The single quotation tells powershell to consider the wildcard characters as normal characters.
         [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
         [String]
         $UserName,
 
         # Specifies the domain for which the user has to get the given user id and password.There is no regular expression involved to search for a given domain. 
         # The user should provide the Target only if he/ she is sure about the Target name, if a non-existing Target is provided as an input, the user may not get the desired output.
         # If the name contains any wildcards then it should be enclosed within  single quotation mark. The single quotation tells powershell to consider the wilcard characters as normal characters.
         # A good example of target can be www.microsoft.com, www.developer.servicenow.com, testserver\users\userAlpha etc.

         [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=1)]
         [String]
         $Target='',

         
         # Specifies the type of credential to return, possible values are [GENERIC, DOMAIN_PASSWORD, DOMAIN_CERTIFICATE, DOMAIN_VISIBLE_PASSWORD, GENERIC_CERTIFICATE, DOMAIN_EXTENDED, MAXIMUM, MAXIMUM_EX].Any value beside the described set will lead to exception.
         # Generic and Generic_Certificate are used for Web Target like www.somesite.com, www.somesite.co.in, www.somesite.edu.us. etc.
         # Domain_Password, Domain_Certificate, Domain_Visible_Password, Domain_Extended are used for server targets like testserver\users\userAlpha, testserver.com\users\superUser, etc.

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=2)]
         [ValidateSet('GENERIC', 'DOMAIN_PASSWORD', 'DOMAIN_CERTIFICATE', 'DOMAIN_VISIBLE_PASSWORD', 'GENERIC_CERTIFICATE', 'DOMAIN_EXTENDED', 'MAXIMUM', 'MAXIMUM_EX')]       
         [String]
         $Type="GENERIC"
     )

     
     
     Begin
     {
        $WarningPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        # $Password = " " | ConvertTo-SecureString -AsPlainText -Force
        $Credential = $null
        $ErrorLog = New-Object System.Collections.Generic.List[String]
        $Status =  "Success"
        $Output = [System.Object]::new()
        
        # Check if the module in installed
        try
        {
            Import-Module CredentialManager
        }

        # If the module does not exists then try installing it
        catch [System.IO.FileNotFoundException]
        {
            try
            {
                Install-Module CredentialManager -Scope CurrentUser
            }

            # there is a failure in the installation, then the script cannot proceed to get the credential. So set the status to Failed.
            catch [System.Exception]
            {
                $ErrorLog.Add($_.Message)
                $ErrorLog.Add("The retrieval failed. The CredentialManager module is missing.")
                $status = "Failed"
            }
        }
        
     }


     Process
     {
        try
        {
            if($status -eq "Success")
            {
                # if target and type are provided
                if($Target -and $Type)
                {
                    $Credentials = Get-StoredCredential -Target $Target -Type $Type
                    $Credential = $Credentials | Where-Object { $_.UserName -ieq $UserName } | Select -First 1
                }

                # if only target is given and type is null
                elseif(($Target -ne "") -and ("" -eq $Type))
                {
                    $Credentials = Get-StoredCredential -Target $Target
                    $Credential = $Credentials | Where-Object { $_.UserName -ieq $UserName } | Select -First 1
                }

                # if only type is given but the target is null
                elseif(($Target -eq "") -and ("" -ne $Type))
                {

                    $Credentials = Get-StoredCredential -Type $Type
                    $Credential = $Credentials | Where-Object { $_.UserName -ieq $UserName } | Select -First 1
                }

                # if both target and type are not given
                elseif(($Target -eq "") -and ("" -eq $Type))
                {
                    $Credentials = Get-StoredCredential
                    $Credential = $Credentials | Where-Object { $_.UserName -ieq $UserName } | Select -First 1
                    
                }

                # if the user with the given details exists.
                if($Credential)
                {
                    $Status = "Success"
                }

                # user not found
                else
                {
                    $Status =  "Failed"
                    $ErrorLog.Add("No credential exists for the given user.")
                }
            }
        }
        catch [System.Exception]
        {
            $Status = "Failed"
            $ErrorLog.Add($_.Message)
        }

     }

     End
     {
        
        if($Status -eq "Success")
        {
            $Output = $Credential
        }

        else
        {
            $Response = @{}
            $Response.Add("Status",$Status)
            $Response.Add("ErrorLog",$ErrorLog)
            $Output = $Response
        }

        return $Output

     }
 
