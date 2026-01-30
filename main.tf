# Storage Transfer APIを自動で有効化する設定
resource "google_project_service" "storage_transfer_api" {
  project = "dotsline-learning"
  service = "storagetransfer.googleapis.com"

  # APIを無効化する際に、他のリソースへの影響を防ぐ設定
  disable_on_destroy = false
}

terraform {
  backend "gcs" {
    bucket = "dotsline-learning-tfstate"
    prefix = "terraform/state"
  }
}

# 1．プロバイダーの設定
provider "google" {
  project = "dotsline-learning"  # あなたのプロジェクトIDに書き換え
  region  = "asia-northeast1"
  user_project_override = true
}

# 2. 転送ジョブの定義
resource "google_storage_transfer_job" "s3_to_gcs_job" {
  description = "Managed by Terraform: S3 to GCS Transfer"

  transfer_spec {
    aws_s3_data_source {
      bucket_name = "handson-s3-transfer-20260130-kawashima" # S3バケット名に書き換え
      aws_access_key {
        access_key_id     = var.aws_access_key_id  # AWSアクセスキーに書き換え
        secret_access_key = var.aws_secret_access_key # AWSシークレットキーに書き換え
      }
    }

    gcs_data_sink {
      bucket_name = "handson-gcs-transfer-20260130-kawashima" # GCSバケット名に書き換え
      path        = "from-s3-tf/"
    }
    
    transfer_options {
      delete_objects_unique_in_sink = false
    }
  }

  schedule {
    # 開始日と終了日を同じ日にすると、その日だけ実行されます
    schedule_start_date {
      year  = 2026
      month = 1
      day   = 30
    }
    schedule_end_date {
      year  = 2026
      month = 1
      day   = 30
    }

    # 時間を指定（例: UTC 08:30 / 日本時間 17:00）
    start_time_of_day {
      hours   = 8
      minutes = 13
      seconds = 0
      nanos   = 0
    }
  }
}

# BigQuery データセットの作成（未作成の場合）
resource "google_bigquery_dataset" "raw_data_dataset" {
  dataset_id = "s3_import_data"
  location   = "asia-northeast1"
}

# GCSのJSONを参照する外部テーブル
resource "google_bigquery_table" "external_json_table" {
  dataset_id = google_bigquery_dataset.raw_data_dataset.dataset_id
  table_id   = "s3_json_logs"

  external_data_configuration {
    autodetect    = true      # スキーマ（列名と型）を自動判別
    source_format = "NEWLINE_DELIMITED_JSON" # 1行1JSONの形式
    source_uris   = ["gs://your-gcs-bucket-name/*.json"] # 参照するGCSパス
  }
}

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}