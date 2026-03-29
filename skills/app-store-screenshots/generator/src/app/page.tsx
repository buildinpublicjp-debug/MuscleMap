'use client';

import { useRef, useState, useCallback, DragEvent } from 'react';
import { toPng } from 'html-to-image';
import { SHOTS, type Lang, type ShotDef } from '@/copy';

const W = 1320;
const H = 2868;
const COPY_TOP = 80;
const PHONE_TOP = 428;
const PHONE_W = 1200;
const PHONE_X = (W - PHONE_W) / 2;
