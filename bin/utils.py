#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright 2024-2026 EMBL - European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


def parse_attrs(attrs_str: str) -> tuple[dict[str, str], list[str]]:
    """Parse a GFF3 column-9 attributes string into a dict and an ordered key list.

    :param attrs_str: Semicolon-separated key=value attribute string from GFF column 9.
    :return: Tuple of (attrs dict, list of keys in original order).
    """
    attrs, order = {}, []
    for part in attrs_str.rstrip(";").split(";"):
        part = part.strip()
        if "=" in part:
            k, v = part.split("=", 1)
            if k not in attrs:
                order.append(k)
            attrs[k] = v
    return attrs, order
