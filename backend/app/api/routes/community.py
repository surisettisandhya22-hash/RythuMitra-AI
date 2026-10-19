from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime
from app.schemas.community_schema import (
    CommunityPost,
    CommunityComment,
    CreatePostRequest,
    AddCommentRequest,
    AgronomistExpert,
)
from app.services.ai_service import ai_service
import json

router = APIRouter()

# In-memory storage with initial rich seed data for Indian farmers
_POSTS: List[CommunityPost] = [
    CommunityPost(
        id="post_1",
        title="వరిలో అగ్గితెగులు (Paddy Blast) నివారణకు జీవామృతం పనిచేస్తుందా?",
        crop="Paddy",
        category="Question",
        author="రాము (Ramu)",
        location="Miryalaguda, Nalgonda",
        time="2 hrs ago",
        content="నా వరి చేలో ఆకులపై కంటి ఆకారంలో మచ్చలు కనిపిస్తున్నాయి. జీవామృతం లేదా ఆవు మూత్రం పిచికారీ చేస్తే నివారించవచ్చా? ఎవరైనా అనుభవమున్న రైతులు సలహా ఇవ్వండి.",
        likes=18,
        commentsCount=3,
        aiVerifiedTip="AI సలహా: ప్రాథమిక దశలో 10 లీటర్ల నీటికి 1 లీటరు జీవామృతం కలపవచ్చు. తెగులు ఉధృతి ఎక్కువగా ఉంటే ట్రైసైక్లాజోల్ (Tricyclazole 75% WP) ఎకరాకు 120 గ్రాములు పిచికారీ చేయండి.",
        comments=[
            CommunityComment(
                id="c_1",
                author="వెంకట్ రావు",
                time="1 hr ago",
                text="ప్రాథమిక దశలో పుల్లటి మజ్జిగ మరియు వేపనూనె కలిపి కొట్టాను, బాగా పనిచేసింది.",
                likes=5
            ),
            CommunityComment(
                id="c_2",
                author="KVK Extension Officer",
                time="30 mins ago",
                text="నైట్రోజన్ (యూరియా) ఎరువులను అధికంగా వేయడం ఆపండి. యూరియా ఎక్కువైతే బ్లాస్ట్ తెగులు వేగంగా వ్యాపిస్తుంది.",
                likes=12
            )
        ]
    ),
    CommunityPost(
        id="post_2",
        title="మిర్చిలో నల్లతామర పురుగు (Black Thrips) నివారణకు సమగ్ర యాజమాన్యం",
        crop="Chilli",
        category="Discussion",
        author="శ్రీనివాసరెడ్డి (Srinivasa Reddy)",
        location="Guntur",
        time="5 hrs ago",
        content="ఈ ఏడాది మిర్చి తోటల్లో తామర పురుగు ఉధృతి తీవ్రంగా ఉంది. పూత రాలిపోకుండా ఉండాలంటే నీలి, పసుపు జిగురు అట్టలు ఎకరాకు కనీసం 30 నుండి 40 ఏర్పాటు చేయండి. రసాయన మందులు మార్చి మార్చి కొట్టాలి.",
        likes=45,
        commentsCount=5,
        aiVerifiedTip="AI సలహా: నీలి జిగురు అట్టలతో పాటు, బవేరియా బాసియానా (Beauveria bassiana) వంటి మిత్ర శిలీంధ్రాలను సాయంత్రం వేళల్లో పిచికారీ చేయడం వల్ల పురుగుల సంతతి అదుపులోకి వస్తుంది.",
        comments=[
            CommunityComment(
                id="c_3",
                author="నాగేశ్వరరావు",
                time="3 hrs ago",
                text="జిగురు అట్టలు పెట్టాక చాలా పురుగులు పడ్డాయి. మంచి ఫలితం ఉంది.",
                likes=7
            )
        ]
    ),
    CommunityPost(
        id="post_3",
        title="ప్రత్తిలో గులాబీ రంగు బొల్లపురుగు (Pink Bollworm) రాకుండా జాగ్రత్తలు",
        crop="Cotton",
        category="Discussion",
        author="మల్లారెడ్డి (Malla Reddy)",
        location="Warangal",
        time="1 day ago",
        content="ప్రత్తి పంట 45 రోజుల దశకు వచ్చినప్పుడు ఎకరాకు 4 నుండి 6 లింగాకర్షక బుట్టలు (Pheromone traps) అమర్చుకోవాలి. మొదటి గుడ్ల దశలోనే నివారించకపోతే కాయలు కుళ్ళిపోతాయి.",
        likes=32,
        commentsCount=2,
        aiVerifiedTip="AI సలహా: వరుసగా ఒకే పురుగుమందు వాడకుండా వేపనూనె (1500 ppm) మరియు సింథటిక్ పైరెథ్రాయిడ్స్ జాగ్రత్తగా మార్చి వాడండి.",
        comments=[]
    ),
    CommunityPost(
        id="post_4",
        title="పీఎం కుసుమ్ (PM-KUSUM) సోలార్ పంపుల దరఖాస్తు ప్రక్రియ ప్రారంభం",
        crop="General",
        category="Scheme",
        author="Rythu Seva Kendra",
        location="Amaravati, AP",
        time="2 days ago",
        content="రైతులకు 60% సబ్సిడీతో సోలార్ వ్యవసాయ పంపుసెట్లు అందించే పథకం అందుబాటులోకి వచ్చింది. ఆసక్తి గల రైతులు పట్టాదారు పాస్ పుస్తకం మరియు ఆధార్ కార్డుతో మీ సేవా లేదా RBK లో దరఖాస్తు చేసుకోవచ్చు.",
        likes=88,
        commentsCount=9,
        aiVerifiedTip="AI సలహా: రైతులకు విద్యుత్ బిల్లుల భారం తగ్గడానికి మరియు పగటిపూట నిరంతర నీటిపారుదలకు సోలార్ పంపులు ఎంతో ప్రయోజనకరమైనవి.",
        comments=[]
    ),
]

_EXPERTS: List[AgronomistExpert] = [
    AgronomistExpert(
        id="exp_1",
        name="Dr. K. Ramakrishna Rao",
        title="Senior Agronomist & Soil Scientist",
        specialization="Crop Nutrition, Soil Reclamation & Organic Farming",
        experience="18+ Years",
        languages=["Telugu", "English", "Hindi"],
        phone="+91 94401 23456",
        availableHours="Mon-Sat (10:00 AM - 5:00 PM)",
        rating=4.9
    ),
    AgronomistExpert(
        id="exp_2",
        name="Dr. M. Lakshmi Prasanna",
        title="Plant Pathologist & IPM Specialist",
        specialization="Pest & Disease Management in Chilli, Cotton & Paddy",
        experience="12+ Years",
        languages=["Telugu", "English"],
        phone="+91 98480 98765",
        availableHours="Mon-Fri (9:30 AM - 4:30 PM)",
        rating=4.8
    ),
    AgronomistExpert(
        id="exp_3",
        name="Er. B. Suresh Kumar",
        title="Horticulture & Micro-Irrigation Consultant",
        specialization="Drip & Sprinkler Design, Polyhouse & Vegetables",
        experience="14+ Years",
        languages=["Telugu", "English"],
        phone="+91 99890 54321",
        availableHours="Tue-Sat (11:00 AM - 6:00 PM)",
        rating=4.7
    ),
]

@router.get("/posts", response_model=List[CommunityPost])
def get_community_posts(
    crop: Optional[str] = None,
    category: Optional[str] = None
):
    results = _POSTS
    if crop and crop.lower() != "all":
        c_lower = crop.lower()
        results = [p for p in results if p.crop.lower() == c_lower or p.crop.lower() == "general"]
    if category and category.lower() != "all":
        cat_lower = category.lower()
        results = [p for p in results if p.category.lower() == cat_lower]
    return results

@router.post("/posts", response_model=CommunityPost)
async def create_community_post(req: CreatePostRequest):
    new_id = f"post_{len(_POSTS) + 1}_{int(datetime.now().timestamp())}"
    
    # Try generating an AI verified agronomist tip
    ai_tip = None
    try:
        prompt = f"A farmer posted on community forum: '{req.title}'. Content: '{req.content}'. Crop: '{req.crop}'. Provide a concise 2-line practical agronomic validation tip in Telugu."
        resp = ai_service.model.generate_content(prompt)
        ai_tip = f"AI సలహా: {resp.text.strip()}"
    except Exception:
        ai_tip = f"AI సలహా: {req.crop} పంటలో సస్యరక్షణ చర్యలు చేపట్టే ముందు వ్యవసాయ క్షేత్ర అధికారిని సంప్రదించండి."

    post = CommunityPost(
        id=new_id,
        title=req.title,
        crop=req.crop,
        category=req.category,
        author=req.author,
        location=req.location or "Farm Field",
        time="Just now",
        content=req.content,
        likes=1,
        commentsCount=0,
        aiVerifiedTip=ai_tip,
        comments=[]
    )
    _POSTS.insert(0, post)
    return post

@router.post("/posts/{post_id}/like")
def toggle_post_like(post_id: str):
    for p in _POSTS:
        if p.id == post_id:
            if p.isLiked:
                p.likes = max(0, p.likes - 1)
                p.isLiked = False
            else:
                p.likes += 1
                p.isLiked = True
            return {"likes": p.likes, "isLiked": p.isLiked}
    raise HTTPException(status_code=404, detail="Post not found")

@router.post("/posts/{post_id}/comments", response_model=CommunityComment)
def add_post_comment(post_id: str, req: AddCommentRequest):
    for p in _POSTS:
        if p.id == post_id:
            comment_id = f"c_{len(p.comments) + 1}_{int(datetime.now().timestamp())}"
            comment = CommunityComment(
                id=comment_id,
                author=req.author,
                time="Just now",
                text=req.text,
                likes=0
            )
            p.comments.append(comment)
            p.commentsCount = len(p.comments)
            return comment
    raise HTTPException(status_code=404, detail="Post not found")

@router.get("/experts", response_model=List[AgronomistExpert])
def get_agronomist_experts():
    return _EXPERTS
