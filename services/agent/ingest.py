"""
Document ingestion script for RAG.

Run this once to seed the database with TVK policy documents.
Run again after adding new documents — duplicates are not checked,
so clear the table first if reseeding: DELETE FROM documents WHERE flavor_id = 'tn-tvk';

Usage:
    python ingest.py
"""

import os
from dotenv import load_dotenv
from embeddings import embed
from db import upsert_document, document_count

load_dotenv("../../.env")

FLAVOR_ID = "tn-tvk"

# Each entry is one document chunk.
# Keep chunks focused on one topic — better retrieval accuracy.
# Ideal chunk size: 150–400 words.
TVK_DOCUMENTS = [
    {
        "title": "TVK Five-Year Vision Overview",
        "content": """Tamilaga Vettri Kazhagam (TVK) under Chief Minister Vijay has committed to a five-year governance roadmap from 2026 to 2031 focused on five pillars: clean water for every household, digital classrooms in every government school, social justice and caste equality, farmer welfare and fair prices, and youth employment through skill development and industry partnerships. The vision is rooted in the Dravidian ideology of Periyar — rational thinking, social equality, and empowerment of the oppressed. Every policy decision is measured against whether it improves the daily life of ordinary Tamil citizens.""",
        "source": "TVK Manifesto 2026",
    },
    {
        "title": "Clean Water for Every Home",
        "content": """TVK's clean water mission aims to provide 24/7 piped drinking water to every household in Tamil Nadu by 2028. The scheme covers 12,525 rural habitations that currently lack reliable water access. An allocation of ₹4,200 crore has been set aside in the first two years. Borewells in drought-prone districts will be replaced with surface water pipelines. Water quality testing labs will be established in every district. Citizens can register water complaints through the CM Helpline (14400) or the TVK Connect app.""",
        "source": "TVK Water Policy 2026",
    },
    {
        "title": "Digital Classrooms — Education Transformation",
        "content": """Every government school in Tamil Nadu will be equipped with digital classrooms, high-speed internet, and smart boards by 2027 under TVK's education initiative. 47,000 government schools are covered in phase one. Teachers will receive 40 hours of digital training annually. Tablets will be distributed to students from Class 6 onwards. The curriculum is being updated to include coding, critical thinking, and Tamil literature. Mid-day meal quality will be monitored through a digital system with parent feedback. School infrastructure funds are tracked publicly to prevent corruption.""",
        "source": "TVK Education Policy 2026",
    },
    {
        "title": "Farmer Welfare and Agricultural Support",
        "content": """TVK's farmer welfare programme includes guaranteed Minimum Support Price (MSP) for paddy, sugarcane, and banana. A Farmer Distress Fund of ₹1,000 crore provides emergency relief within 72 hours for crop loss due to floods or drought. Free soil health cards are issued annually. Interest-free loans up to ₹1 lakh are available through cooperative banks. Cold storage facilities are being built in 32 districts to reduce post-harvest losses. Farmers can register for all schemes at their nearest Agriculture Office or through the TVK Connect app.""",
        "source": "TVK Farmer Policy 2026",
    },
    {
        "title": "Youth Employment and Skill Development",
        "content": """TVK aims to create 20 lakh new jobs over five years through a combination of government hiring, private sector partnerships, and entrepreneurship support. The Tamil Nadu Skill Mission is being expanded to 500 centres offering free training in IT, manufacturing, healthcare, and green energy. Startups registered in Tamil Nadu receive a three-year tax holiday and access to government office space at subsidised rent. Special employment drives are held quarterly in every district. Women and SC/ST candidates get priority placement through the 40% reservation in all new government jobs.""",
        "source": "TVK Employment Policy 2026",
    },
    {
        "title": "Social Justice and Caste Equality",
        "content": """Social justice is the founding principle of TVK. The government has enacted strict penalties for caste-based discrimination in public spaces, restaurants, and temples. A Social Justice Tribunal has been established in every district with fast-track hearings for discrimination cases. Inter-caste marriage couples receive a ₹2.5 lakh support grant. Dalits and tribal communities receive priority under all housing, education, and employment schemes. TVK has committed to abolishing manual scavenging completely by 2027, with affected families receiving ₹10 lakh rehabilitation support.""",
        "source": "TVK Social Justice Policy 2026",
    },
    {
        "title": "Free Bus Travel for Women",
        "content": """TVK has extended the free bus travel scheme for women on all Tamil Nadu State Transport Corporation (TNSTC) buses. This covers all routes across the state including express and town buses. Women above 60 years also receive free travel on suburban trains in partnership with Southern Railway. The scheme benefits approximately 1.2 crore women daily. Women travelling after 9 PM are entitled to police escort on request at major bus stands. Complaints about bus safety can be reported to the Women's Safety Helpline at 181.""",
        "source": "TVK Women Welfare Schemes 2026",
    },
    {
        "title": "CM Vijay — Background and Ideology",
        "content": """Vijay (Joseph Vijay Chandrasekhar) founded Tamilaga Vettri Kazhagam (TVK) on February 27, 2024, and led the party to victory in the 2026 Tamil Nadu assembly elections. Born in Chennai, he is the son of filmmaker S.A. Chandrasekhar and Shoba. Before entering politics, he was one of Tamil cinema's biggest stars with a career spanning over 30 years. He follows the Dravidian ideology rooted in the teachings of Periyar E.V. Ramasamy — rationalism, social equality, and anti-casteism. He has repeatedly stated that his goal is not power but to build a corruption-free, educated, and equal Tamil Nadu.""",
        "source": "TVK Leader Profile",
    },
    {
        "title": "How to Contact CM Office and File Complaints",
        "content": """Citizens can reach Chief Minister Vijay's office through the following channels: CM Helpline: 14400 (24/7, Tamil and English). CM Cell email: cmcell@tn.gov.in. In-person grievance redressal is available every Monday at the Secretariat from 10 AM to 1 PM. Online complaints can be filed at cm.tn.gov.in/grievances. For urgent issues like water supply, electricity, or road damage, call 1913 (state control room). For women's safety issues, call 181. For farmer distress, call 1800-425-1551 (toll free). All complaints receive a reference number and must be resolved within 21 working days under the Right to Service Act.""",
        "source": "CM Office Contact Information",
    },
    {
        "title": "Housing — Kalaignar Housing Scheme",
        "content": """TVK has relaunched and expanded the Kalaignar Housing Scheme targeting 5 lakh new homes for the homeless and economically weaker sections by 2028. Each house is 300 sq ft minimum with electricity, water connection, and toilet. Land pattas are issued in the woman's name. SC/ST families receive 100% subsidy. Other EWS families receive ₹3.5 lakh grant with a low-interest loan for the remaining cost. Urban slum residents are relocated to permanent flats with shops and green spaces. Applications are open at taluk offices and online at housing.tn.gov.in.""",
        "source": "TVK Housing Policy 2026",
    },
    {
        "title": "Health — Free Medicine and Hospital Scheme",
        "content": """Government hospitals under TVK provide free medicines, free diagnostics, free surgery, and free specialist consultations. The Amma Mini Clinics programme has been expanded to 2,000 urban locations providing primary care within 1 km of every city resident. The Chief Minister's Comprehensive Health Insurance Scheme (CMCHIS) now covers ₹5 lakh per family per year for procedures at empanelled private hospitals. Mental health services have been added to all district hospitals. A mobile health van visits every village once a month. The 104 health helpline operates 24/7 for medical advice in Tamil and English.""",
        "source": "TVK Health Policy 2026",
    },
    {
        "title": "Anti-Corruption and Transparency",
        "content": """TVK has established a Vigilance and Anti-Corruption Directorate with enhanced powers to investigate government officials without prior sanction. All government contracts above ₹10 lakh are published on a public procurement portal. Asset declarations of all ministers and MLAs are published annually. A Whistleblower Protection Act shields citizens who report corruption. The CM's office has a dedicated anti-corruption cell reachable at 044-28880000. TVK has committed to passing a Right to Information (RTI) fast-track law ensuring responses within 7 days for basic public services information.""",
        "source": "TVK Governance and Transparency Policy 2026",
    },
]


def chunk_text(text: str, max_words: int = 350) -> list[str]:
    """Split long text into smaller chunks for better embedding accuracy.

    Why chunk? Embedding a 2000-word document into one vector loses detail.
    A query about water policy won't match well against a vector that also
    encodes housing, education, and health content. Smaller focused chunks
    produce more accurate similarity matches.
    """
    words = text.split()
    if len(words) <= max_words:
        return [text]
    chunks = []
    for i in range(0, len(words), max_words):
        chunks.append(" ".join(words[i:i + max_words]))
    return chunks


def ingest():
    print(f"Starting ingestion for flavor: {FLAVOR_ID}")
    print(f"Total documents to ingest: {len(TVK_DOCUMENTS)}\n")

    total_chunks = 0
    for doc in TVK_DOCUMENTS:
        chunks = chunk_text(doc["content"])
        for i, chunk in enumerate(chunks):
            title = doc["title"] if len(chunks) == 1 else f"{doc['title']} (part {i+1})"
            print(f"  Embedding: {title} ...", end=" ", flush=True)
            vector = embed(chunk)
            upsert_document(
                flavor_id=FLAVOR_ID,
                title=title,
                content=chunk,
                embedding=vector,
                source=doc.get("source"),
            )
            total_chunks += 1
            print("✓")

    print(f"\nDone. {total_chunks} chunks ingested into documents table.")


if __name__ == "__main__":
    ingest()
