
Connect-AzAccount

$AccessToken = (Get-AzAccessToken -ResourceUrl "https://api.loganalytics.io/").token | ConvertFrom-SecureString -AsPlainText

$workspaceId = "YourWorkspaceIdHere"
$url = "https://api.loganalytics.io/v1/workspaces/$workspaceId/query"

$headers = @{
  "Authorization" = "Bearer $AccessToken"
  "Content-Type"  = "application/json"
}

$Query = "WVDConnections | where TimeGenerated >= ago(90d)"

$body = '{"query":"' + $Query + '"}'

$Result = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body

function Convert-TableToObjects {
  param($table)

  $cols = $table.columns.name
  # Handle duplicate columns by appending a suffix
  $colCounts = @{}
  $uniqueCols = foreach ($col in $cols) {
    if ($colCounts.ContainsKey($col)) {
      $colCounts[$col]++
      "$col$($colCounts[$col])"
    }
    else {
      $colCounts[$col] = 1
      $col
    }
  }

  $objects = foreach ($row in $table.rows) {
    $props = @{}
    for ($i = 0; $i -lt $uniqueCols.Count; $i++) {
      $props[$uniqueCols[$i]] = $row[$i]
    }
    [pscustomobject]$props
  }
  return $objects
}

$Objects = Convert-TableToObjects -table $Result.tables

$Objects[0]