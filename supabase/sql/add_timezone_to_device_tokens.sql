-- Migration: Add timezone column to device_tokens
-- Run this in the Supabase SQL Editor once.

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'Europe/Berlin';
