/*
The MIT License (MIT)

Copyright (c) 2020-2021 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "Plugins.h"

#include "HarbourMediaPlugin.h"
#include "HarbourPolicyPlugin.h"

// Workaround for certain plugins not being allowed in harbour apps

// ==========================================================================
// Plugins::Gallery
// ==========================================================================

class Plugins::Gallery: public HarbourPluginLoader {
    Gallery(QQmlEngine* aEngine);
    void registerTypes(const char* aModule, int v1, int v2);
public:
    static void registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2);
};

Plugins::Gallery::Gallery(QQmlEngine* aEngine) :
    HarbourPluginLoader(aEngine, "QtDocGallery", 5, 0)
{
}

void Plugins::Gallery::registerTypes(const char* aModule, int v1, int v2)
{
    reRegisterType("DocumentGallery", aModule, v1, v2);
    reRegisterType("DocumentGalleryItem", aModule, v1, v2);
    reRegisterType("DocumentGalleryModel", aModule, v1, v2);
    reRegisterType("GalleryStartsWithFilter", aModule, v1, v2);
}

void Plugins::Gallery::registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2)
{
    static Gallery* gInstance = Q_NULLPTR;
    if (!gInstance) {
        (gInstance = new Gallery(aEngine))->registerTypes(aModule, v1, v2);
    }
}

// ==========================================================================
// Plugins::Contacts
// ==========================================================================

class Plugins::Contacts: public HarbourPluginLoader {
    Contacts(QQmlEngine* aEngine);
    void registerTypes(const char* aModule, int v1, int v2);
public:
    static void registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2);
};

Plugins::Contacts::Contacts(QQmlEngine* aEngine) :
    HarbourPluginLoader(aEngine, "org.nemomobile.contacts", 1, 0)
{
}

void Plugins::Contacts::registerTypes(const char* aModule, int v1, int v2)
{
    reRegisterType("PeopleVCardModel", aModule, v1, v2);
}

void Plugins::Contacts::registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2)
{
    static Contacts* gInstance = Q_NULLPTR;
    if (!gInstance) {
        (gInstance = new Contacts(aEngine))->registerTypes(aModule, v1, v2);
    }
}

// ==========================================================================
// Plugins::Thumbnailer
// ==========================================================================

class Plugins::Thumbnailer: public HarbourPluginLoader {
    Thumbnailer(QQmlEngine* aEngine);
    void registerTypes(const char* aModule, int v1, int v2);
public:
    static void registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2);
};

Plugins::Thumbnailer::Thumbnailer(QQmlEngine* aEngine) :
    HarbourPluginLoader(aEngine, "org.nemomobile.thumbnailer", 1, 0)
{
}

void Plugins::Thumbnailer::registerTypes(const char* aModule, int v1, int v2)
{
    reRegisterType("Thumbnail", aModule, v1, v2);
}

void Plugins::Thumbnailer::registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2)
{
    static Thumbnailer* gInstance = Q_NULLPTR;
    if (!gInstance) {
        (gInstance = new Thumbnailer(aEngine))->registerTypes(aModule, v1, v2);
    }
}

// ==========================================================================
// Plugins
// ==========================================================================

void Plugins::registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2)
{
    Gallery::registerTypes(aEngine, aModule, v1, v2);
    Contacts::registerTypes(aEngine, aModule, v1, v2);
    Thumbnailer::registerTypes(aEngine, aModule, v1, v2);
    HarbourMediaPlugin::registerTypes(aEngine, aModule, v1, v2);
    HarbourPolicyPlugin::registerTypes(aEngine, aModule, v1, v2);
}
